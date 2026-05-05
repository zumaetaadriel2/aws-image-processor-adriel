import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from 'sharp';

const s3Client = new S3Client({});

export const handler = async (event) => {
    for (const record of event.Records) {
        const s3EventData = JSON.parse(record.body).Records[0].s3;
        const bucketName = s3EventData.bucket.name;
        const originalKey = decodeURIComponent(s3EventData.object.key.replace(/\+/g, ' '));

        try {
            console.log(`(Adriel Zumaeta) Procesando imagen: ${originalKey}`);
            
            // 1. Descarga S3
            const { Body } = await s3Client.send(new GetObjectCommand({ Bucket: bucketName, Key: originalKey }));
            const imgBuffer = Buffer.concat(await Body.toArray());

            // 2. Transformación con Sharp (Círculo 40x40)
            const maskSvg = Buffer.from('<svg width="40" height="40"><circle cx="20" cy="20" r="20" fill="white"/></svg>');
            
            const croppedBuffer = await sharp(imgBuffer)
                .resize(40, 40, { fit: 'cover' })
                .composite([{ input: maskSvg, blend: 'dest-in' }])
                .png()
                .toBuffer();

            // 3. Subida a 'processed/'
            const finalKey = originalKey.replace('uploads/', 'processed/').replace(/\.[^.]+$/, '_circular.png');
            
            await s3Client.send(new PutObjectCommand({
                Bucket: bucketName,
                Key: finalKey,
                Body: croppedBuffer,
                ContentType: 'image/png'
            }));

            console.log(`Imagen recortada exitosamente: ${finalKey}`);
        } catch (err) {
            console.error(`Fallo al procesar ${originalKey}:`, err);
            throw err; // Obliga a SQS a reintentar
        }
    }
};