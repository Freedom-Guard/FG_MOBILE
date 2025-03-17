import 'dart:ffi';
import 'dart:io';

final DynamicLibrary nativeLib = Platform.isAndroid
    ? DynamicLibrary.open("licore.so")
    : DynamicLibrary.process();

typedef NativeStartFunction = Void Function();
typedef DartStartFunction = void Function();

final DartStartFunction start = nativeLib
    .lookupFunction<NativeStartFunction, DartStartFunction>("start");

