import { Controller, Post, Body } from '@nestjs/common';
import { PaymentsService } from './payments.service';

@Controller('payments')
export class PaymentsController {
    constructor(private readonly paymentsService: PaymentsService) { }

    @Post('create-order')
    async createOrder(@Body() body: { amount: number }) {
        // Basic validation
        if (!body.amount) {
            throw new Error('Amount is required');
        }
        const order = await this.paymentsService.createOrder(body.amount);
        return order;
    }

    @Post('verify')
    verifyPayment(@Body() body: { orderId: string, paymentId: string, signature: string }) {
        return this.paymentsService.verifyPayment(body.orderId, body.paymentId, body.signature);
    }
}
