function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents || '{}');
    const secret = PropertiesService.getScriptProperties().getProperty('WEBHOOK_SECRET');
    if (!secret || data.secret !== secret) return respuesta({ ok: false, error: 'unauthorized' });

    const english = String(data.language || '').toLowerCase() === 'en';
    const copy = english ? {
      subject: `Booking confirmed ${data.reference} · ${data.route}`,
      title: 'Your booking is confirmed',
      intro: 'Thank you for choosing Rutas B de Barcelona. Keep these details:',
      reference: 'Reference', route: 'Tour', date: 'Date', time: 'Selected time',
      meeting: 'Meeting point', transport: 'Public transport', closing: 'See you in Barcelona.'
    } : {
      subject: `Reserva confirmada ${data.reference} · ${data.route}`,
      title: 'Tu reserva está confirmada',
      intro: 'Gracias por elegir Rutas B de Barcelona. Guarda estos datos:',
      reference: 'Referencia', route: 'Ruta', date: 'Fecha', time: 'Horario elegido',
      meeting: 'Punto de encuentro', transport: 'Transporte público', closing: 'Nos vemos en Barcelona.'
    };

    const texto = [copy.title, '', `${copy.reference}: ${data.reference}`, `${copy.route}: ${data.route}`, `${copy.date}: ${data.date}`, `${copy.time}: ${data.time}`, '', `${copy.meeting}: ${data.meetingPoint}`, data.address, `${copy.transport}: ${data.transport}`, '', copy.closing, 'Rutas B de Barcelona'].join('\n');
    const html = `<div style="font-family:Arial,sans-serif;color:#15251f;line-height:1.6;max-width:620px;margin:auto"><img src="cid:rutasBLogo" alt="Rutas B de Barcelona" style="display:block;width:150px;height:auto;margin:0 0 28px"><h1 style="font-family:Georgia,serif;font-size:32px;margin-bottom:8px">${esc(copy.title)}</h1><p>${esc(copy.intro)}</p><div style="background:#f3efe7;padding:22px;margin:24px 0"><p><strong>${esc(copy.reference)}:</strong> ${esc(data.reference)}</p><p><strong>${esc(copy.route)}:</strong> ${esc(data.route)}</p><p><strong>${esc(copy.date)}:</strong> ${esc(data.date)}</p><p style="font-family:Georgia,serif;font-size:20px;color:#123c32"><strong>${esc(copy.time)}: ${esc(data.time)}</strong></p></div><div style="border-left:5px solid #be6245;padding:10px 20px;margin:24px 0"><p style="font-family:Georgia,serif;font-size:20px;color:#123c32"><strong>${esc(copy.meeting)}</strong></p><p><strong>${esc(data.meetingPoint)}</strong></p><p>${esc(data.address)}</p><p>${esc(copy.transport)}: ${esc(data.transport)}</p></div><p>${esc(copy.closing)}</p><p><strong>Rutas B de Barcelona</strong></p></div>`;

    const logo = UrlFetchApp.fetch(data.logoUrl || 'https://rutasbdebarcelona.github.io/images/marca/rutas-b-logo.png').getBlob().setName('rutas-b-logo.png');
    GmailApp.sendEmail(data.to, copy.subject, texto, {
      htmlBody: html,
      inlineImages: { rutasBLogo: logo },
      name: 'Rutas B de Barcelona'
    });
    return respuesta({ ok: true, language: english ? 'en' : 'es' });
  } catch (error) {
    return respuesta({ ok: false, error: String(error) });
  }
}
function esc(valor) { return String(valor || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;'); }
function respuesta(datos) { return ContentService.createTextOutput(JSON.stringify(datos)).setMimeType(ContentService.MimeType.JSON); }
