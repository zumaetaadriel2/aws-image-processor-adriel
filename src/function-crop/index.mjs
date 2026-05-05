import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from 'sharp';

const s3Client = new S3Client({ region: process.env.AWS_REGION });

export const handler = async (event) => {
    const records = event.Records;
    
    for (const record of records) {
        const body = JSON.parse(record.body);
        
        // Verificación en caso de eventos de prueba de SQS
        if (!body.Records || !body.Records[0].s3) continue;

        const s3EventData = body.Records[0].s3;
        const bucketName = s3EventData.bucket.name;
        const originalKey = decodeURIComponent(s3EventData.object.key.replace(/\+/g, ' '));

        try {
            const { Body } = await s3Client.send(new GetObjectCommand({ Bucket: bucketName, Key: originalKey }));
            
            // AWS SDK v3: convertir el stream a buffer
            const chunks = [];
            for await (const chunk of Body) {
                chunks.push(chunk);
            }
            const imgBuffer = Buffer.concat(chunks);

            // Crear recorte circular 40x40 (Sharp)
            const maskSvg = Buffer.from('<svg width="40" height="40"><circle cx="20" cy="20" r="20" fill="white"/></svg>');
            
            const croppedBuffer = await sharp(imgBuffer)
                .resize(40, 40, { fit: 'cover' })
                .composite([{ input: maskSvg, blend: 'dest-in' }])
                .png()
                .toBuffer();

            const finalKey = originalKey.replace('uploads/', 'processed/').replace(/\.[^.]+$/, '_circular.png');
            
            await s3Client.send(new PutObjectCommand({
                Bucket: bucketName,
                Key: finalKey,
                Body: croppedBuffer,
                ContentType: 'image/png'
            }));

            console.log(`Successfully processed and saved to ${finalKey}`);
        } catch (err) {
            console.error(`Failed processing ${originalKey}:`, err);
            // El throw es crítico: hace que SQS devuelva el mensaje a la cola.
            // Si falla 3 veces, se enviará automáticamente a la DLQ.
            throw err; 
        }
    }
};