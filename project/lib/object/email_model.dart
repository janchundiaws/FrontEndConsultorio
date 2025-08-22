import 'dart:io';
import 'package:mailer/mailer.dart';

class EmailModel {
  final Address from;
  final List<String> recipients;
  final List<String>? ccRecipients;
  final List<String>? bccRecipients;
  final String subject;
  final String? text;
  final String? html;
  final List<File>? attachments;

  EmailModel({
    required this.from,
    required this.recipients,
    this.ccRecipients,
    this.bccRecipients,
    required this.subject,
    this.text,
    this.html,
    this.attachments,
  });

  Message toMessage() {
    final msg = Message()
      ..from = from
      ..recipients.addAll(recipients)
      ..subject = subject;
    if (ccRecipients != null) msg.ccRecipients.addAll(ccRecipients!);
    if (bccRecipients != null) msg.bccRecipients.addAll(bccRecipients!);
    if (text != null) msg.text = text!;
    if (html != null) msg.html = html!;
    if (attachments != null) {
      for (var file in attachments!) {
        msg.attachments.add(FileAttachment(file));
      }
    }
    return msg;
  }
}
