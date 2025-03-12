// Suggested code may be subject to a license. Learn more: ~LicenseLog:1320827024.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1569211286.
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class publicConnect {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/log.txt');
  }

  Future<File> LOGLOG(text, type) async {
    final file = await _localFile;
    return file.writeAsString('[$type]: $text \n', mode: FileMode.append);
  }

  Future<String> setupVibeCore() async {
    final Directory? appDir =
        await getExternalStorageDirectory(); // 🚀 تغییر مسیر
    if (appDir == null) throw Exception('عدم دسترسی به حافظه خارجی');

    final String coreDirPath = '${appDir.path}/core';
    final String libDirPath = '$coreDirPath/lib';
    final String coreBinaryPath = '$coreDirPath/vibe-core';

    await Directory(coreDirPath).create(recursive: true);
    await Directory(libDirPath).create(recursive: true);

    // انتقال vibe-core
    final ByteData coreData = await rootBundle.load('assets/core/vibe-core');
    final File coreFile = File(coreBinaryPath);
    await coreFile.writeAsBytes(coreData.buffer.asUint8List(), flush: true);
    await Process.run('chmod', ['777', coreBinaryPath]); // 🔥 دادن مجوز اجرا

    // انتقال libcore.so
    final ByteData soData = await rootBundle.load('assets/core/lib/libcore.so');
    final File soFile = File('$libDirPath/libcore.so');
    await soFile.writeAsBytes(soData.buffer.asUint8List(), flush: true);

    print('✅ Vibe-Core آماده اجرا شد! مسیر: $coreBinaryPath');
    return coreBinaryPath;
  }
}

class ConnectAuto extends publicConnect {
  Future<String> runVibeCore(List<String> args) async {
    final Directory? appDir = await getExternalStorageDirectory();
    if (appDir == null) throw Exception('عدم دسترسی به حافظه خارجی');

    final String coreDirPath = '${appDir.path}/core';
    final String coreBinaryPath = '$coreDirPath/vibe-core';
    final String libDirPath = '$coreDirPath/lib';

    final process = await Process.start('sh', [
      '-c',
      'LD_LIBRARY_PATH=$libDirPath $coreBinaryPath ${args.join(' ')}',
    ]);
    String Result = '';
    process.stdout.transform(SystemEncoding().decoder).listen((data) {
      Result = 'stdout: $data';
    });

    process.stderr.transform(SystemEncoding().decoder).listen((data) {
      Result = 'stdout: $data';
    });

    final exitCode = await process.exitCode;
    Result += 'Vibe-Core اجرا شد. کد خروج: $exitCode';
    return Result;
  }

  Future<String> connect(List<String> args) async {
    try {
      await setupVibeCore();
      var resu = await runVibeCore(["--help"]);
      return resu;
    } catch (e) {
      return "Error: $e";
    }
  }
}

class Connect extends publicConnect {}
