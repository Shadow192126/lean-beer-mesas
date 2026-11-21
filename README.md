# Lean Beer Multi-Mesa

Tablero colaborativo en español para sesiones Lean Beer con más de 20 participantes agrupados por mesas. Cada mesa tiene temas, acuerdos, votos, presencia, temporizador y votación «¿Seguimos?». El panel maestro consolida las mesas en Markdown y Excel, con una hoja por mesa.

## Probar en esta laptop

Abre `index.html` en Brave. El modo demo guarda los cambios en ese navegador. Puedes abrir el panel maestro y un tablero en pestañas distintas. Excel necesita acceso al CDN de SheetJS. El cronómetro y el aviso sonoro requieren que la pestaña esté activa para escucharse de inmediato y que hayas interactuado con la página.

## Usar la versión publicada

La [app en GitHub Pages](https://shadow192126.github.io/lean-beer-mesas/) ya está conectada a Supabase. Pulsa **Crear sesión colaborativa**, guarda el enlace del panel maestro y usa **Copiar enlace** para compartir cada mesa.

## Evaluar la reunión con Plus/Delta

En el Panel maestro, pulsa **Cerrar sesión y abrir evaluación** al terminar. Los enlaces de las mesas muestran el formulario de evaluación. Usa **Copiar enlace de evaluación** para reenviar el enlace a un grupo. Cada navegador puede enviar una respuesta por mesa, con un comentario sobre lo que funcionó y otro sobre lo que cambiaría. El Panel maestro agrupa las respuestas por mesa y las incluye en el acta Markdown y en una hoja del Excel.

## Configurar otro despliegue

1. En tu proyecto de Supabase, ejecuta `supabase.sql` en SQL Editor.
2. En `index.html`, completa `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con la URL y la clave publicable del proyecto. Nunca pongas una clave secreta de servicio en HTML.
3. Publica la rama principal desde Settings → Pages → Deploy from a branch, con la carpeta raíz. Abre la URL de Pages.
4. Pulsa **Crear sesión colaborativa**. Conserva el enlace completo del panel maestro, incluido el fragmento privado `#facilitador=…`.
5. Usa **Copiar enlace** para repartir la URL correspondiente a cada mesa. Esos enlaces no incluyen la clave de facilitador. Crea una sesión nueva para cada reunión.

La sincronización consulta Supabase aproximadamente cada dos segundos. El acceso de participantes se basa en el enlace de sesión y presupone un grupo de confianza. Cualquiera que tenga un enlace de esa sesión puede leer sus mesas. El nombre y los votos de la interfaz se asocian al navegador. El límite de votos individual se aplica en el cliente. No uses esta versión para votaciones vinculantes o información confidencial.

## Acta ejecutiva con un LLM local

Copia el Markdown del panel maestro y completa el siguiente prompt en tu modelo local.

> Actúa como facilitador Lean Beer. A partir del reporte que adjunto, redacta un acta en español con un resumen global de hasta cinco líneas, los patrones que se repiten en al menos dos mesas, los acuerdos y acciones por mesa, y de tres a cinco temas pendientes prioritarios según votos o impacto explícito. Indica en qué mesas aparece cada patrón. Usa «Responsable por definir» si el acta no asigna a nadie y «Pendiente de documentar» cuando un tema concluido no tenga acuerdos. No inventes hechos, responsables ni acuerdos.
>
> Reporte de la sesión:
> [Pega aquí el Markdown exportado]

