// examples/l04_schemas.ts
import * as z from 'zod';
import type { Equal, Expect } from './type-tests.ts';
import { show } from './show.ts';

// 1. The type derived from the schema: one definition, checked at run time and at compile time
const ViewerInfoSchema = z.object({
  connectionId: z.string(),
  color: z.string(),
  browser: z.enum(['Edge', 'Chrome', 'Firefox', 'Safari', 'Unknown']),
  connectedAt: z.iso.datetime(),
  displayName: z.string().nullable(), // the C# record's string? DisplayName = null is sent as null
  avatarUrl: z.string().nullable(),
});
type ViewerInfo = z.infer<typeof ViewerInfoSchema>;
type _1 = Expect<Equal<ViewerInfo['displayName'], string | null>>;

// 2. Or the schema checked against an interface written by hand: satisfies z.ZodType<T> fails if they drift apart.
// GA's ViewerInfo in DataLoader.ts declares displayName?: string, which null doesn't fit (errors/l04_schemas.ts)
interface ViewerInfoFixed {
  connectionId: string;
  color: string;
  browser: 'Edge' | 'Chrome' | 'Firefox' | 'Safari' | 'Unknown';
  connectedAt: string;
  displayName: string | null;
  avatarUrl: string | null;
}
const CheckedViewerInfoSchema = ViewerInfoSchema satisfies z.ZodType<ViewerInfoFixed>;
type _2 = Expect<Equal<z.infer<typeof CheckedViewerInfoSchema>, ViewerInfoFixed>>;

// 3. Input and output types differ once the schema transforms: strings in the message, a Date and a number in the program
const CameraSyncSchema = z.object({
  px: z.number(),
  py: z.number(),
  pz: z.number(),
  sender: z.string(),
  sentAt: z.iso.datetime().transform((text) => new Date(text)),
  zoom: z.coerce.number().default(1),
});
type CameraSyncInput = z.input<typeof CameraSyncSchema>;
type CameraSync = z.output<typeof CameraSyncSchema>;
type _3 = Expect<Equal<CameraSyncInput['sentAt'], string>>;
type _4 = Expect<Equal<CameraSync['sentAt'], Date>>;
type _5 = Expect<Equal<CameraSync['zoom'], number>>;
const camera = CameraSyncSchema.parse({ px: 0, py: 2, pz: 10, sender: 'c3', sentAt: '2026-09-15T12:00:00Z', zoom: '1.5' });
show('camera.sentAt.getUTCHours()', camera.sentAt.getUTCHours());
show('camera.zoom', camera.zoom);

// 4. A brand added by the schema: the only way to get a NodeId is to pass the check (lesson 3)
const NodeIdSchema = z.string().regex(/^[a-z0-9-]+$/).brand<'NodeId'>();
type NodeId = z.infer<typeof NodeIdSchema>;
const nodeId: NodeId = NodeIdSchema.parse('policy-7');
show('nodeId', nodeId);
show("safeParse('Policy 7').success", NodeIdSchema.safeParse('Policy 7').success);

// 5. Unknown keys: stripped by default, kept with z.looseObject, rejected with z.strictObject
const payload = { connectionId: 'c3', color: '#d2a8ff', browser: 'Firefox', connectedAt: '2026-09-15T12:00:00Z', displayName: null, avatarUrl: null, isAdmin: true };
show("'isAdmin' in parse(payload)", 'isAdmin' in ViewerInfoSchema.parse(payload));
const strict = z.strictObject(ViewerInfoSchema.shape).safeParse(payload);
show('strictObject issues', strict.error?.issues.map((issue) => `${issue.code}: ${issue.message}`));

// 6. The schema as JSON Schema, the format that OpenAPI documents and C# or Java generators use
show('z.toJSONSchema(NodeIdSchema)', z.toJSONSchema(NodeIdSchema));
