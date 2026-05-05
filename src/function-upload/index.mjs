import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { randomUUID } from 'crypto';

// Reutilizamos la conexión TCP (Mejor rendimiento y menor costo)
const s3Client = new S3Client({ region: process.env.AWS_REGION });

export const handler = async (event) => {
    try {
        const targetBucket = process.env.S3_BUCKET;
        const targetPrefix = process.env.UPLOAD_PREFIX || 'uploads/';
        
        // Verificación de Payload
        if (!event.body) {
            return { statusCode: 400, body: JSON.stringify({ error: "No image data provided" }) };
        }

        const fileExt = (event.headers['content-type'] || 'image/png').split('/')[1];
        const uniqueFileName = `${randomUUID()}.${fileExt}`;
        const objectKey = `${targetPrefix}${uniqueFileName}`;

        const imageBuffer = event.isBase64Encoded 
            ? Buffer.from(event.body, 'base64') 
            : Buffer.from(event.body);

        await s3Client.send(new PutObjectCommand({
            Bucket: targetBucket,
            Key: objectKey,
            Body: imageBuffer,
            ContentType: event.headers['content-type'] || 'image/png'
        }));

        return {
            statusCode: 201,
            body: JSON.stringify({ message: "Upload success", file: uniqueFileName })
        };
    } catch (error) {
        console.error("Upload error:", error);
        return { statusCode: 500, body: JSON.stringify({ error: "Internal Server Error" }) };
    }
};