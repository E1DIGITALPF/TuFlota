const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {registroDiario} = require("./registroDiario");

admin.initializeApp();

// eslint-disable-next-line max-len
exports.actualizarDesgasteCamiones = functions.pubsub.schedule("every 5 hours").timeZone("America/New_York").onRun((context) => {
  const db = admin.firestore();

  return db.collection("trucks").get()
      .then((querySnapshot) => {
        const updatePromises = [];

        querySnapshot.forEach((doc) => {
          const camion = doc.data();
          const nuevoDesgaste = calcularNuevoDesgaste(camion);

          if (camion.wearLevel > 1 && nuevoDesgaste <= 1) {
            // eslint-disable-next-line max-len
            const camionDetalle = `Marca: ${camion.brand}, Modelo: ${camion.model}, Placa: ${camion.plate}`;
            const chatMessage = {
              // eslint-disable-next-line max-len
              text: `El camión ${camionDetalle} ha alcanzado un nivel crítico de desgaste y requiere atención.`,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              userId: "system",
              userName: "Sistema 🤖",
              isAdmin: true,
              isSystemMessage: true,
            };
            db.collection("globalChat").add(chatMessage);

            notificarOperadores(doc.id, camion);
            camion.status = "Requiere atención";
          }

          const updatePromise = db.collection("trucks").doc(doc.id).update({
            wearLevel: nuevoDesgaste,
            status: camion.status,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          });
          updatePromises.push(updatePromise);
        });

        return Promise.all(updatePromises);
      })
      .catch((error) => {
        console.error("Error al obtener la lista de camiones:", error);
        return null;
      });
});

exports.registroDiario = registroDiario;

// eslint-disable-next-line require-jsdoc
function calcularNuevoDesgaste(camion) {
  const r = 1;
  const currentDate = new Date();
  const lastUpdatedDate = new Date(camion.lastUpdated.toDate());
  const timeDiff = Math.abs(currentDate.getTime() - lastUpdatedDate.getTime());
  const diffHours = timeDiff / (1000 * 3600);
  const nuevoWearLevel = Math.floor(camion.wearLevel - (r * diffHours));
  return Math.max(1, nuevoWearLevel);
}

// eslint-disable-next-line require-jsdoc
function notificarOperadores(truckId, camion) {
  const db = admin.firestore();
  return db.collection("operators").get().then((querySnapshot) => {
    const tokens = [];
    querySnapshot.forEach((doc) => {
      const operatorData = doc.data();
      if (operatorData.token) {
        tokens.push(operatorData.token);
      }
    });

    if (tokens.length > 0) {
      const message = {
        data: {
          truckId: truckId,
          brand: camion.brand,
          model: camion.model,
          color: camion.color,
          plate: camion.plate,
          action: "REQUIRES_ATTENTION",
        },
        notification: {
          title: "⚠ Alerta de Desgaste de Camión",
          // eslint-disable-next-line max-len
          body: `El camión ${camion.brand} ${camion.model} de color ${camion.color} con placa ${camion.plate} ha alcanzado un nivel crítico de desgaste y requiere atención.`,
        },
        tokens: tokens,
      };

      admin.messaging().sendMulticast(message)
          .then((response) => {
            // eslint-disable-next-line max-len
            console.log(`${response.successCount} mensajes enviados exitosamente`);
          })
          .catch((error) => {
            console.log("Error enviando mensaje:", error);
          });
    } else {
      console.log("No hay tokens disponibles para enviar notificaciones.");
    }
  });
}
