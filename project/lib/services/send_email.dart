import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:odontologo/object/email_model.dart';

Future<void> sendEmail(EmailModel emailData) async {
  final username = 'tucorreo@gmail.com';
  final password = 'tu_password_o_app_password';

  final message = emailData.toMessage();
  final smtpServer = gmail(username, password);

  try {
    final report = await send(message, smtpServer);
    print('Correo enviado: ${report.toString()}');
  } on MailerException catch (e) {
    print('Error:');
    for (var p in e.problems) {
      print(' - ${p.code}: ${p.msg}');
    }
  }

  // También puedes enviar múltiples mensajes manteniendo la conexión:
  var connection = PersistentConnection(smtpServer);
  await connection.send(message);
  // Puedes enviar otros mensajes...
  await connection.close();
}
