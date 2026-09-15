// errors/l04_schemas.ts
import * as z from 'zod';

const ViewerInfoSchema = z.object({
  connectionId: z.string(),
  color: z.string(),
  browser: z.string(),
  connectedAt: z.iso.datetime(),
  displayName: z.string().nullable(),
  avatarUrl: z.string().nullable(),
});

// GA's ViewerInfo, as DataLoader.ts declares it
interface ViewerInfo {
  connectionId: string;
  color: string;
  browser: string;
  connectedAt: string;
  displayName?: string;
  avatarUrl?: string | null;
}

const checked = ViewerInfoSchema satisfies z.ZodType<ViewerInfo>;

// The parsed value is unknown until the result is narrowed
const result = ViewerInfoSchema.safeParse(JSON.parse('{}'));
console.log(checked, result.data.color);
