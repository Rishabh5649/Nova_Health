import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const Razorpay = require('razorpay');

@Injectable()
export class PaymentsService {
    private razorpayClient: any;
    private isMockMode: boolean = false;

    constructor(private prisma: PrismaService) {
        const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_test_1DP5mmOlF5G5ag';
        const keySecret = process.env.RAZORPAY_KEY_SECRET || 'SimulatedSecret';

        // If using the placeholder secret, enable Mock Mode
        if (keySecret === 'SimulatedSecret') {
            this.isMockMode = true;
            console.warn('PaymentsService: Running in MOCK MODE. No real payments will be processed.');
        }

        this.razorpayClient = new Razorpay({
            key_id: keyId,
            key_secret: keySecret,
        });
    }

    async createOrder(amount: number, currency: string = 'INR') {
        if (this.isMockMode) {
            return {
                id: 'order_' + Math.random().toString(36).substring(7),
                entity: 'order',
                amount: amount * 100,
                amount_paid: 0,
                amount_due: amount * 100,
                currency: currency,
                receipt: `receipt_${Date.now()}`,
                status: 'created',
                attempts: 0,
                created_at: Math.floor(Date.now() / 1000),
            };
        }

        try {
            const options = {
                amount: amount * 100, // Amount in paise
                currency,
                receipt: `receipt_${Date.now()}`,
            };

            const order = await this.razorpayClient.orders.create(options);
            return order;
        } catch (error) {
            console.error('Razorpay Error:', error);
            throw new BadRequestException('Failed to create Razorpay order');
        }
    }

    verifyPayment(orderId: string, paymentId: string, signature: string) {
        if (this.isMockMode) {
            return { success: true, message: 'Payment verified (Mock)' };
        }

        const secret = process.env.RAZORPAY_KEY_SECRET || 'SimulatedSecret';

        const generated_signature = crypto
            .createHmac('sha256', secret)
            .update(orderId + "|" + paymentId)
            .digest('hex');

        if (generated_signature === signature) {
            return { success: true, message: 'Payment verified' };
        } else {
            throw new BadRequestException('Invalid payment signature');
        }
    }
}
