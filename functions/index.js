const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();
const db = admin.firestore();

// 🔥 CONFIGURAÇÕES
const CONFIG = {
  entrada: { hora: 8, minuto: 0 },
  saidaAlmoco: { hora: 12, minuto: 0 },
  retornoAlmoco: { hora: 13, minuto: 0 },
  saidaSegQui: { hora: 18, minuto: 0 },
  saidaSex: { hora: 17, minuto: 0 },
  alertaEntrada: { hora: 7, minuto: 55 },
  alertaAlmoco: { hora: 12, minuto: 5 },
  tempoAlmoco: { horas: 1, minutos: 5 },
};

// 🔥 VERIFICAR ALERTAS (a cada 5 minutos)
exports.verificarAlertas = functions.pubsub
  .schedule('*/5 * * * *')
  .timeZone('America/Sao_Paulo')
  .onRun(async (context) => {
    console.log('⏰ Verificando alertas...');
    const agora = new Date();
    const diaSemana = agora.getDay(); // 0=domingo, 6=sábado
    
    // 🔥 Buscar todos os funcionários ativos
    const funcionariosSnapshot = await db
      .collection('funcionarios')
      .where('ativo', '==', true)
      .get();

    const funcionarios = [];
    funcionariosSnapshot.forEach(doc => {
      funcionarios.push({ id: doc.id, ...doc.data() });
    });

    console.log(`📋 Verificando ${funcionarios.length} funcionários`);

    for (const funcionario of funcionarios) {
      await verificarAlertasFuncionario(funcionario, agora, diaSemana);
    }

    console.log('✅ Verificação concluída');
    return null;
  });

// 🔥 VERIFICAR ALERTAS DE UM FUNCIONÁRIO
async function verificarAlertasFuncionario(funcionario, agora, diaSemana) {
  const hoje = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate());
  const inicioDia = new Date(hoje);
  const fimDia = new Date(hoje);
  fimDia.setDate(fimDia.getDate() + 1);

  // 🔥 Buscar registros de hoje
  const registrosSnapshot = await db
    .collection('registros_ponto')
    .where('funcionarioId', '==', funcionario.id)
    .where('dataHora', '>=', inicioDia.toISOString())
    .where('dataHora', '<', fimDia.toISOString())
    .get();

  const registros = [];
  registrosSnapshot.forEach(doc => {
    registros.push(doc.data());
  });

  const hora = agora.getHours();
  const minuto = agora.getMinutes();

  // 🔥 1. ALERTA DE ENTRADA (07:55) - Segunda a Sexta
  if (diaSemana >= 1 && diaSemana <= 5) {
    if (hora === CONFIG.alertaEntrada.hora && minuto === CONFIG.alertaEntrada.minuto) {
      const temEntrada = registros.some(r => r.tipo === 'entrada');
      if (!temEntrada) {
        await enviarNotificacao(
          funcionario.id,
          '⏰ Lembrete: não esqueça de registrar seu ponto',
          'Registre sua entrada agora!'
        );
      }
    }

    // 🔥 2. ALERTA DE SAÍDA PARA ALMOÇO (12:05) - Segunda a Sexta
    if (hora === CONFIG.alertaAlmoco.hora && minuto === CONFIG.alertaAlmoco.minuto) {
      const temSaidaAlmoco = registros.some(r => r.tipo === 'saidaAlmoco');
      if (!temSaidaAlmoco) {
        await enviarNotificacao(
          funcionario.id,
          '⏰ Hora do almoço! Registre seu ponto antes de sair',
          'Registre sua saída para almoço!'
        );
      }
    }

    // 🔥 3. ALERTA DE RETORNO DO ALMOÇO (1h05 após saída) - Dias úteis e Sábado
    const saidaAlmoco = registros.find(r => r.tipo === 'saidaAlmoco');
    if (saidaAlmoco) {
      const dataSaida = new Date(saidaAlmoco.dataHora);
      const diffMinutes = Math.floor((agora - dataSaida) / (1000 * 60));
      
      if (diffMinutes >= (CONFIG.tempoAlmoco.horas * 60 + CONFIG.tempoAlmoco.minutos)) {
        const temRetorno = registros.some(r => r.tipo === 'retornoAlmoco');
        if (!temRetorno) {
          await enviarNotificacao(
            funcionario.id,
            '⏰ Voltando ao trabalho? Não esqueça de bater o ponto',
            'Registre seu retorno do almoço!'
          );
        }
      }
    }

    // 🔥 4. ALERTA DE SAÍDA (quando TOTAL EFETIVO > TOTAL PREVISTO)
    const totalPrevisto = calcularTotalPrevisto(diaSemana);
    const totalEfetivo = calcularTotalEfetivo(registros);
    
    // 🔥 Só dispara se o funcionário já bateu entrada
    const temEntrada = registros.some(r => r.tipo === 'entrada');
    if (temEntrada && totalEfetivo > totalPrevisto) {
      const temSaida = registros.some(r => r.tipo === 'saida');
      if (!temSaida) {
        await enviarNotificacao(
          funcionario.id,
          '⏰ Encerrando o dia? Não esqueça de registrar sua saída',
          'Registre sua saída!'
        );
      }
    }
  }
}

// 🔥 CALCULAR TOTAL PREVISTO (em minutos)
function calcularTotalPrevisto(diaSemana) {
  if (diaSemana === 5) { // Sexta
    return 9 * 60; // 09:00 (08:00 às 17:00)
  }
  return 10 * 60; // 10:00 (08:00 às 18:00) - Segunda a Quinta
}

// 🔥 CALCULAR TOTAL EFETIVO (em minutos)
function calcularTotalEfetivo(registros) {
  const entrada = registros.find(r => r.tipo === 'entrada');
  const saida = registros.find(r => r.tipo === 'saida');
  
  if (!entrada || !saida) return 0;
  
  const dataEntrada = new Date(entrada.dataHora);
  const dataSaida = new Date(saida.dataHora);
  return Math.floor((dataSaida - dataEntrada) / (1000 * 60));
}

// 🔥 ENVIAR NOTIFICAÇÃO PUSH
async function enviarNotificacao(funcionarioId, titulo, corpo) {
  try {
    // 🔥 Buscar token do funcionário
    const tokenSnapshot = await db
      .collection('tokens_notificacao')
      .where('funcionarioId', '==', funcionarioId)
      .get();

    if (tokenSnapshot.empty) {
      console.log(`❌ Funcionário ${funcionarioId} sem token`);
      return;
    }

    const tokens = [];
    tokenSnapshot.forEach(doc => {
      tokens.push(doc.data().token);
    });

    // 🔥 Enviar notificação
    const payload = {
      notification: {
        title: titulo,
        body: corpo,
        sound: 'default',
      },
      data: {
        tipo: 'alerta_ponto',
        funcionarioId: funcionarioId,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    };

    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`✅ Notificação enviada para ${funcionarioId}`);
    return response;
  } catch (error) {
    console.error('❌ Erro ao enviar notificação:', error);
  }
}

// 🔥 REGISTRAR TOKEN DO DISPOSITIVO
exports.registrarToken = functions.https.onCall(async (data) => {
  const { funcionarioId, token } = data;
  
  if (!funcionarioId || !token) {
    throw new functions.https.HttpsError('invalid-argument', 'Dados incompletos');
  }

  try {
    await db.collection('tokens_notificacao').doc(token).set({
      funcionarioId,
      token,
      dataCriacao: new Date().toISOString(),
    });
    
    return { success: true };
  } catch (error) {
    console.error('❌ Erro ao registrar token:', error);
    throw new functions.https.HttpsError('internal', 'Erro ao registrar token');
  }
});

// 🔥 REMOVER TOKEN (quando o funcionário desloga)
exports.removerToken = functions.https.onCall(async (data) => {
  const { token } = data;
  
  if (!token) {
    throw new functions.https.HttpsError('invalid-argument', 'Token obrigatório');
  }

  try {
    await db.collection('tokens_notificacao').doc(token).delete();
    return { success: true };
  } catch (error) {
    console.error('❌ Erro ao remover token:', error);
    throw new functions.https.HttpsError('internal', 'Erro ao remover token');
  }
});