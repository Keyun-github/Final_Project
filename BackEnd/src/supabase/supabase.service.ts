import { Injectable, Logger } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private readonly logger = new Logger(SupabaseService.name);
  private supabase: SupabaseClient | null = null;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_KEY;

    if (!supabaseUrl || !supabaseKey) {
      this.logger.warn(
        'SUPABASE_URL or SUPABASE_KEY is not set. Supabase features will be disabled.',
      );
      return;
    }

    this.supabase = createClient(supabaseUrl, supabaseKey);
  }

  getClient(): SupabaseClient | null {
    return this.supabase;
  }

  isEnabled(): boolean {
    return this.supabase !== null;
  }

  async uploadFile(
    bucket: string,
    filePath: string,
    fileData: Buffer,
  ): Promise<string | null> {
    if (!this.supabase) {
      this.logger.error('Supabase is not configured');
      return null;
    }

    try {
      const { data, error } = await this.supabase.storage
        .from(bucket)
        .upload(filePath, fileData, {
          contentType: 'image/jpeg',
          upsert: true,
        });

      if (error) {
        this.logger.error(`Supabase upload error: ${error.message}`);
        return null;
      }

      const { data: urlData } = this.supabase.storage
        .from(bucket)
        .getPublicUrl(filePath);

      return urlData.publicUrl;
    } catch (e) {
      this.logger.error(
        `Upload to Supabase failed: ${e instanceof Error ? e.message : String(e)}`,
      );
      return null;
    }
  }
}
