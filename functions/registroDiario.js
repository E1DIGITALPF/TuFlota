const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.registroDiario = functions.pubsub.schedule('59 23 * * *').timeZone('America/New_York').onRun((context) => {
  const db = admin.firestore();
  const today = new Date();
  const dateKey = today.toISOString().split('T')[0];  // Formato 'yyyy-mm-dd'

  return db.collection('trucks').get()
    .then((querySnapshot) => {
      const writePromises = [];

      querySnapshot.forEach((doc) => {
        const wearLevel = doc.data().wearLevel || 0;
        const updates = {};
        updates[`historialDesgaste.${dateKey}`] = wearLevel;

        const updatePromise = db.collection('trucks').doc(doc.id).update(updates);
        writePromises.push(updatePromise);
      });

      return Promise.all(writePromises);
    })
    .catch((error) => {
      console.error('Error al realizar el registro diario de los camiones:', error);
      return null;
    });
});
