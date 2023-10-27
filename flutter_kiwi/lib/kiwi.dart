import 'dart:convert';
import 'package:dio/dio.dart';

// ignore: non_constant_identifier_names
class Kiwi {
  static final Kiwi instance = Kiwi._instance();
  factory Kiwi() {
    return instance;
  }
  Kiwi._instance();

  static String? ip;
  static Map<String, dynamic>? globalHeaders;
  Dio dio = Dio();
  Kiwi._() {
    ///< 具体初始化代码
  }

  static Message api(MessageClosure? performer,
      {MessageClosure? responser,
      Map<String, dynamic>? params,
      Map<String, dynamic>? headers}) {
    final message = Message(performer,
        responser: responser, params: params, headers: headers);
    return message;
  }

  static get(Message? msg, String? path) {
    Kiwi.req(HttpRequestMethod.GET, msg, path);
  }

  static post(Message? msg, String? path) {
    Kiwi.req(HttpRequestMethod.POST, msg, path);
  }

  static delete(Message? msg, String? path) {
    Kiwi.req(HttpRequestMethod.DELETE, msg, path);
  }

  static put(Message? msg, String? path) {
    Kiwi.req(HttpRequestMethod.PUT, msg, path);
  }

  static req(HttpRequestMethod? method, Message? msg, String? path) {
    msg?.path = path;
    if (method != null) {
      msg?.method = method;
    }
    Kiwi.instance.request(msg);
  }

  Options _options(Message message) {
    Map<String, dynamic> headers = Map<String, dynamic>();

    if (globalHeaders?.isEmpty == false) {
      headers.addAll(globalHeaders!);
    }

    if (message.headers?.isEmpty == false) {
      headers.addAll(message.headers!);
    }

    return Options(method: message.methodValue, headers: headers);
  }

  Future request(Message? message) async {
    if (message == null) return;
    try {
      final path = (ip ?? "") + (message.path ?? "");
      Response response = await dio.request(path,
          queryParameters:
              message.method != HttpRequestMethod.POST ? message.input : null,
          data: message.method != HttpRequestMethod.POST ? null : message.input,
          options: _options(message));
      // ignore: unnecessary_null_comparison
      print(
          "Kiwi Request Path:${path},Input:${message.input},Response:${response}}");
      message.data = response;
      if (message.response == null) {
        message.onStatusChanged(FAIL);
      } else {
        final status = message.response!["status"] as int;
        if (status != 1) {
          message.onStatusChanged(FAIL);
        } else {
          message.onStatusChanged(SUCCEED);
        }
      }
    } catch (error) {
      print(
          "Kiwi Request Path:${message.path},Input:${message.input},Error:${error}}");
      message.onStatusChanged(FAIL);
    }
  }
}

const SENDING = HttpRequestStatus.SENDING;
const SUCCEED = HttpRequestStatus.SUCCEED;
const CANCEL = HttpRequestStatus.CANCEL;
const FAIL = HttpRequestStatus.FAIL;

enum HttpRequestMethod { GET, POST, DELETE, PUT }

enum HttpRequestStatus {
  SENDING,
  SUCCEED,
  CANCEL,
  FAIL,
}

typedef MessageClosure = Function(Message);
const kMsgOutputKey = "kMsgOutPut";

class Message {
  String? path;
  HttpRequestMethod method = HttpRequestMethod.GET;
  Map<String, dynamic>? input;
  Map<String, dynamic>? headers;
  Response? data;
  HttpRequestStatus? status;
  MessageClosure? performer, responser;
  Map<String, dynamic> output = <String, dynamic>{};
  Map<String, dynamic>? get response => json.decode(data.toString());

  Message(MessageClosure? performer,
      {MessageClosure? responser,
      Map<String, dynamic>? params,
      Map<String, dynamic>? headers}) {
    this.performer = performer;
    this.responser = responser;
    this.input = params;
    this.headers = headers;
  }

  String get methodValue {
    switch (method) {
      case HttpRequestMethod.GET:
        return "get";
      case HttpRequestMethod.POST:
        return "post";
      case HttpRequestMethod.DELETE:
        return "delete";
      case HttpRequestMethod.PUT:
        return "put";
    }
  }

  Message send() {
    onStatusChanged(SENDING);
    return this;
  }

  onStatusChanged(HttpRequestStatus? status) {
    if (status == this.status) return;
    this.status = status;
    if (performer != null) {
      performer!(this);
    }
    if (responser != null) {
      responser!(this);
    }
  }
}
