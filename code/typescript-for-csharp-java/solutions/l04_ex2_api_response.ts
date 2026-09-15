// solutions/l04_ex2_api_response.ts
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
}
type Guard<T> = (value: unknown) => value is T;

// The guard for T is a parameter: the check on data runs, instead of being promised
function isApiResponseOf<T>(value: unknown, isData: Guard<T>): value is ApiResponse<T> {
  return (
    typeof value === 'object' &&
    value !== null &&
    'success' in value &&
    typeof value.success === 'boolean' &&
    'data' in value &&
    isData(value.data)
  );
}

const isStringArray: Guard<string[]> = (value): value is string[] =>
  Array.isArray(value) && value.every((item) => typeof item === 'string');

for (const text of ['{"success": true, "data": ["C", "E", "G"]}', '{"success": true, "data": "C major"}']) {
  const json: unknown = JSON.parse(text);
  if (isApiResponseOf(json, isStringArray)) {
    console.log('notes:', json.data.join(' '));
  } else {
    console.log('rejected:', text);
  }
}
