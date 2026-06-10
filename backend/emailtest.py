import resend

resend.api_key = "re_WREUengh_AGLdCAJFRFiNVNJzR13qF7i6"

params: resend.Emails.SendParams = {
  "from": "Acme <support@zapfenapp.de>",
  "to": ["engl.devmail@gmail.com"],
  "subject": "hello world",
  "html": "<p>it works!</p>"
}

email = resend.Emails.send(params)
print(email)