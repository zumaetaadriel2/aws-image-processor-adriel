import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { randomUUID } from 'crypto';

const s3Client = new S3Client({});

export const handler = async (event) => {
    console.log("Iniciando procesamiento de carga (Adriel Zumaeta):", event.requestContext?.requestId);
    
    try {
        const targetBucket = process.env.S3_BUCKET;
        const targetPrefix = process.env.UPLOAD_PREFIX || 'uploads/';
        
        const fileExt = event.headers['content-type']?.split('/')[1] || 'png';
        const uniqueFileName = `${randomUUID()}.${fileExt}`;
        const objectKey = `${targetPrefix}${uniqueFileName}`;

        const imageBuffer = event.isBase64Encoded 
            ? Buffer.from(event.body, 'base64') 
            : Buffer.from(event.body);

        if (!imageBuffer.length) throw new Error("Payload vacío.");

        await s3Client.send(new PutObjectCommand({
            Bucket: targetBucket,
            Key: objectKey,
            Body: imageBuffer,
            ContentType: event.headers['content-type'] || 'image/png'
        }));

        return {
            statusCode: 201,
            body: JSON.stringify({ author: "Adriel Zumaeta", status: "success", file: uniqueFileName })
        };
    } catch (error) {
        console.error("Error en function-upload:", error);
        return { statusCode: 500, body: JSON.stringify({ error: "Internal Server Error" }) };
    }
};