import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class ExcelExportHelper {
  
  // 🔥 SALVAR E COMPARTILHAR EXCEL (ANDROID/iOS)
  static Future<void> salvarECompartilhar(Uint8List bytes, String nomeArquivo) async {
    try {
      // 🔥 Salvar no diretório temporário
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$nomeArquivo');
      await file.writeAsBytes(bytes);
      
      debugPrint('✅ Excel salvo em: ${file.path}');
      
      // 🔥 COMPARTILHAR - Usando o método correto (NÃO DEPRECATED)
      await SharePlus.instance.share(
        ShareParams(
          text: '📊 Relatório de ponto gerado!\nArquivo: $nomeArquivo',
          files: [XFile(file.path)],
        ),
      );
      
    } catch (e) {
      debugPrint('❌ Erro ao salvar/compartilhar: $e');
      rethrow;
    }
  }
  
  // 🔥 SALVAR EXCEL NO DISPOSITIVO (ANDROID)
  static Future<void> salvarExcel(Uint8List bytes, String nomeArquivo) async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final file = File('${downloadsDir.path}/$nomeArquivo');
        await file.writeAsBytes(bytes);
        debugPrint('✅ Excel salvo em: ${file.path}');
      } else {
        // Fallback para diretório temporário
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$nomeArquivo');
        await file.writeAsBytes(bytes);
        debugPrint('✅ Excel salvo em: ${file.path}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar Excel: $e');
      rethrow;
    }
  }
}