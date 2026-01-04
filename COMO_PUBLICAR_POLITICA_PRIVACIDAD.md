# Cómo Publicar la Política de Privacidad

Google Play Store requiere una URL pública donde esté disponible tu Política de Privacidad. Aquí te muestro varias opciones para publicarla.

---

## 🚀 Opción 1: GitHub Pages (Recomendada - Gratis y Fácil)

GitHub Pages es la forma más sencilla y gratuita de publicar tu Política de Privacidad.

### Pasos:

1. **Sube el archivo `privacy-policy.html` a GitHub**

   - Si ya tienes un repositorio en GitHub:
     - Sube el archivo `privacy-policy.html` a la carpeta raíz de tu repositorio
   
   - Si NO tienes repositorio, crea uno nuevo:
     ```bash
     # En la carpeta finanzasapp
     git init
     git add privacy-policy.html
     git commit -m "Agregar política de privacidad"
     git branch -M main
     git remote add origin https://github.com/TU_USUARIO/financially.git
     git push -u origin main
     ```

2. **Habilita GitHub Pages en tu repositorio**

   - Ve a tu repositorio en GitHub
   - Click en **Settings** (Configuración)
   - En el menú lateral, busca **Pages**
   - En **Source**, selecciona **Deploy from a branch**
   - Selecciona la rama `main` (o `master`)
   - Selecciona la carpeta `/ (root)`
   - Click en **Save**

3. **Espera unos minutos**

   GitHub Pages puede tardar 1-5 minutos en activarse.

4. **Tu URL será:**

   ```
   https://TU_USUARIO.github.io/financially/privacy-policy.html
   ```

   O si está en la raíz del repositorio:
   ```
   https://TU_USUARIO.github.io/financially-privacy/privacy-policy.html
   ```

   > **Nota:** Si el repositorio se llama `financially`, la URL será `https://TU_USUARIO.github.io/financially/privacy-policy.html`

### ⚡ Alternativa rápida con un repositorio dedicado:

Si quieres una URL más simple, crea un repositorio nuevo solo para la política:

1. Crea un nuevo repositorio llamado `financially-privacy` (o similar)
2. Sube solo `privacy-policy.html`
3. Habilita GitHub Pages
4. Tu URL será: `https://TU_USUARIO.github.io/financially-privacy/privacy-policy.html`

---

## 🌐 Opción 2: Tu Propio Dominio

Si ya tienes un dominio (por ejemplo, gestiondinero.site), puedes:

1. **Subir el archivo a tu servidor**

   ```bash
   # Por ejemplo, usando FTP o SSH
   scp privacy-policy.html usuario@tudominio.com:/var/www/html/
   ```

2. **Tu URL sería:**

   ```
   https://gestiondinero.site/privacy-policy.html
   ```

   O si quieres una estructura más organizada:
   ```
   https://gestiondinero.site/app/financially/privacy-policy.html
   ```

---

## 📝 Opción 3: Servicios Gratuitos de Alojamiento

### Netlify Drop (Sin cuenta requerida)

1. Ve a https://app.netlify.com/drop
2. Arrastra y suelta la carpeta con `privacy-policy.html`
3. Obtendrás una URL como: `https://random-name-123.netlify.app/privacy-policy.html`

### Vercel

1. Ve a https://vercel.com
2. Crea una cuenta (gratis)
3. Arrastra y suelta el archivo
4. Obtendrás una URL como: `https://proyecto.vercel.app/privacy-policy.html`

---

## ✅ Verificación

Una vez publicado, verifica que:

1. ✅ La URL es accesible desde un navegador
2. ✅ El contenido se muestra correctamente
3. ✅ La URL usa HTTPS (requerido por Google Play)
4. ✅ El archivo está en formato HTML o texto plano

---

## 📋 Para Google Play Console

Cuando tengas tu URL, úsala en Google Play Console:

1. Ve a **Políticas y programas** > **Política de privacidad**
2. Ingresa tu URL (por ejemplo: `https://tu-usuario.github.io/financially/privacy-policy.html`)
3. Guarda los cambios

---

## 🔄 Actualizar la Política

Si necesitas actualizar la política más adelante:

1. Edita el archivo `privacy-policy.html`
2. Actualiza la fecha de "Última actualización"
3. Sube el archivo actualizado al mismo lugar
4. Google Play no requiere que vuelvas a enviar, pero es buena práctica mantenerla actualizada

---

## 💡 Recomendación

**Usa GitHub Pages** porque:
- ✅ Es completamente gratis
- ✅ Usa HTTPS automáticamente
- ✅ Es fácil de actualizar
- ✅ Es confiable y estable
- ✅ Google Play lo acepta sin problemas

---

## 📧 Contacto

Si tienes problemas publicando la política, puedes contactar:
- Email: afesdev2025@gmail.com

