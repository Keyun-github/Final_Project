import {
  Injectable,
  Logger,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Unit } from './units.entity.js';

@Injectable()
export class UnitsService {
  private readonly logger = new Logger(UnitsService.name);

  constructor(
    @InjectRepository(Unit)
    private readonly unitsRepo: Repository<Unit>,
  ) {}

  /** Public list of active units. Used by both admin and customer apps. */
  async findAll(): Promise<Unit[]> {
    return this.unitsRepo.find({
      where: { isActive: true },
      order: { isDefault: 'DESC', name: 'ASC' },
    });
  }

  async findOne(id: number): Promise<Unit> {
    const unit = await this.unitsRepo.findOne({ where: { id } });
    if (!unit) throw new NotFoundException('Unit not found');
    return unit;
  }

  async create(name: string): Promise<Unit> {
    const trimmed = (name ?? '').trim();
    if (!trimmed) {
      throw new BadRequestException('Unit name is required');
    }
    if (trimmed.length > 50) {
      throw new BadRequestException('Unit name must be 50 characters or less');
    }

    const existing = await this.unitsRepo.findOne({
      where: { name: trimmed },
    });
    if (existing) {
      if (existing.isActive) {
        throw new ConflictException(`Unit "${trimmed}" already exists`);
      }
      // Re-activate the previously soft-deleted entry.
      existing.isActive = true;
      return this.unitsRepo.save(existing);
    }

    const unit = this.unitsRepo.create({
      name: trimmed,
      isDefault: false,
      isActive: true,
    });
    const saved = await this.unitsRepo.save(unit);
    this.logger.log(`Created unit "${saved.name}" (id=${saved.id})`);
    return saved;
  }

  /**
   * Soft-delete a unit. Default units (isDefault=true) cannot be removed —
   * admin must keep them so legacy products keep a valid display value.
   */
  async remove(id: number): Promise<{ message: string; unit: Unit }> {
    const unit = await this.findOne(id);
    if (unit.isDefault) {
      throw new BadRequestException(
        'Default units cannot be deleted (KG, Box, Sack - 25kg, Sack - 50kg, Piece)',
      );
    }
    unit.isActive = false;
    await this.unitsRepo.save(unit);
    this.logger.log(`Soft-deleted unit "${unit.name}" (id=${unit.id})`);
    return { message: `Unit "${unit.name}" deleted`, unit };
  }
}
