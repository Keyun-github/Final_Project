import {
  Entity,
  PrimaryColumn,
  Column,
  UpdateDateColumn,
} from 'typeorm';

/**
 * Singleton row (id is always 1) holding the store's pickup address
 * and coordinates. Admin can update this from the admin panel; all
 * server-side route / dispatch logic reads from here so the source
 * code does not need to change when the store moves.
 */
@Entity('store_config')
export class StoreConfig {
  @PrimaryColumn({ type: 'int', default: 1 })
  id!: number;

  @Column({ length: 500 })
  address!: string;

  @Column({ type: 'double precision' })
  lat!: number;

  @Column({ type: 'double precision' })
  lng!: number;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @Column({ name: 'updated_by', type: 'varchar', length: 100, nullable: true })
  updatedBy!: string | null;
}