const admin = require('firebase-admin');

// 🔥 Inicializar Firebase Admin
if (!admin.apps.length) {
  const serviceAccount = {
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  };
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

// 🔥 CONFIGURAÇÕES
const CONFIG = {
  alertaEntrada: { hora: 7, minuto: 55 },
  alertaAlmoco: { hora: 12, minuto: 5 },
  tempoAlmoco: { horas: 1, minutos: 5 },
};

async function verificarAlertas() {
  console.log('⏰ Verificando alertas...');
  const agora = new Date();
  const diaSemana = agora.getDay();

  try {
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
  } catch (error) {
    console.error('❌ Erro:', error);
  }
}

// 🔥 FUNÇÃO PARA VERIFICAR ALERTAS DE UM FUNCIONÁRIO
async function verificarAlertasFuncionario(funcionario, agora, diaSemana) {
  const hoje = new Date(agora.getFullYear(), agora.getMonth(), agora.getDate());
  const inicioDia = new Date(hoje);
  const fimDia = new Date(hoje);
  fimDia.setDate(fimDia.getDate() + 1);

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

  // 🔥 ALERTA DE ENTRADA (07:55) - Segunda a Sexta
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

    // 🔥 ALERTA DE SAÍDA PARA ALMOÇO (12:05)
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

    // 🔥 ALERTA DE SAÍDA
    const totalPrevisto = diaSemana === 5 ? 9 * 60 : 10 * 60;
    const totalEfetivo = calcularTotalEfetivo(registros);
    
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

  // 🔥 ALERTA DE RETORNO DO ALMOÇO - Todos os dias
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
}

function calcularTotalEfetivo(registros) {
  const entrada = registros.find(r => r.tipo === 'entrada');
  const saida = registros.find(r => r.tipo === 'saida');
  
  if (!entrada || !saida) return 0;
  
  const dataEntrada = new Date(entrada.dataHora);
  const dataSaida = new Date(saida.dataHora);
  return Math.floor((dataSaida - dataEntrada) / (1000 * 60));
}

async function enviarNotificacao(funcionarioId, titulo, corpo) {
  try {
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

    await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`✅ Notificação enviada para ${funcionarioId}`);
  } catch (error) {
    console.error('❌ Erro ao enviar notificação:', error);
  }
}

// 🔥 Executar
verificarAlertas();