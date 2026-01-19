import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards } from '@nestjs/common';
import { RemindersService } from './reminders.service';
import { CreateReminderDto } from './dto/create-reminder.dto';
import { UpdateReminderDto } from './dto/update-reminder.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtUser } from '../auth/current-user.decorator';


@Controller('reminders')
@UseGuards(JwtAuthGuard)
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) { }

  @Post()
  create(
    @CurrentUser() user: JwtUser,
    @Body() dto: CreateReminderDto
  ) {
    return this.remindersService.create(user!.sub, dto);
  }

  @Get('me')
  findMyReminders(@CurrentUser() user: JwtUser) {
    return this.remindersService.findMyReminders(user!.sub);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @CurrentUser() user: JwtUser,
    @Body() dto: UpdateReminderDto
  ) {
    return this.remindersService.update(id, user!.sub, dto);
  }

  @Delete(':id')
  remove(
    @Param('id') id: string,
    @CurrentUser() user: JwtUser,
  ) {
    return this.remindersService.remove(id, user!.sub);
  }
}
