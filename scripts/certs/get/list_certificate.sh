# 获取 apk 的证书
keytool -list -printcert -jarfile app.apk

# 获取 apk 解包后 CERT.{RSA|DSA} 的证书
keytool -printcert -file app/META-INF/CERT.{RSA|DSA}

# 获取 keystore 的证书
keytool -list -keystore app.keystore -storepass {password}