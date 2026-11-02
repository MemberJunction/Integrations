/**
 * Measures response text that stays in memory. Not a test file itself (vitest only collects `*.test.ts`).
 */
import { setFlagsFromString } from 'node:v8';
import { runInNewContext } from 'node:vm';

setFlagsFromString('--expose-gc');
const collectGarbage = runInNewContext('gc') as () => void;

/** Size of the filler in one simulated response. Large enough that Node stores the text outside the JS heap. */
export const PAGE_MB = 4;

/** `xml` with a filler element appended, as one string stored outside the JS heap (as `fetch().text()` stores a large body). */
export function LargeResponse(xml: string): string {
    return Buffer.from(`${xml}<zz_filler>${'x'.repeat(PAGE_MB * 1048576)}</zz_filler>`).toString('latin1');
}

/** MB of text Node holds outside the JS heap, measured after a full garbage collection. */
export async function ExternalTextMB(): Promise<number> {
    await new Promise(resolve => setTimeout(resolve, 0));
    // V8 keeps the input of the last regex match (RegExp.lastMatch); point it at a small string.
    /./.exec('.');
    collectGarbage();
    collectGarbage();
    return process.memoryUsage().external / 1048576;
}
