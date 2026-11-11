// Actual App WarCwlService -> installed client -> local API Worker -> HTTP provider.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
const origin = new URL(process.env.CLASHKING_E2E_BASE_URL);
assert.equal(origin.hostname, '127.0.0.1');
assert.equal(process.env.CLASHKING_DISPOSABLE_TIMESCALE, '1');
const apiRoot = process.env.CLASHKING_E2E_API_REPO;
const { build } = createRequire(join(apiRoot, 'package.json'))('esbuild');
const dir = mkdtempSync(join(tmpdir(), 'ck-app-clash-outcomes-'));
try {
  const output = join(dir, 'check.mjs');
  await build({
    stdin: {
      resolveDir: process.cwd(),
      loader: 'ts',
      contents: `
 import assert from 'node:assert/strict';
 import {createApiClient,httpTransport} from '@clashking/api-client';
 import {WarCwlService} from './src/features/war/data/war-cwl-service';
 const client=createApiClient({baseUrl:process.env.CLASHKING_E2E_BASE_URL,transport:httpTransport((request)=>{request.headers.set('authorization','Bearer '+process.env.CLASHKING_E2E_ACCESS_TOKEN);return fetch(request);})});
 const service=new WarCwlService(client),tag='#2PP';
 const control=async(status:number,reason:string,cwlStatus=404,cwlReason='notFound')=>{await fetch(process.env.CLASHKING_E2E_PROVIDER_URL+'/test/control',{method:'POST',body:JSON.stringify({status,reason,cwlStatus,cwlReason})});};
 await control(200,'');await service.loadAllWarData([tag],{throwOnError:true});
 assert.equal(service.getWarCwlByTag(tag)?.warInfo.state,'notInWar');
 await control(403,'accessDenied');await service.loadAllWarData([tag],{throwOnError:true});
 assert.equal(service.getWarCwlByTag(tag)?.warInfo.state,'accessDenied');
 const retained=service.getWarCwlByTag(tag);
 for(const [status,reason] of [[403,'accessDenied.invalidIp'],[503,'inMaintenance'],[503,'upstreamUnavailable'],[500,'unknownException']] as const){
  await control(status,reason);await assert.rejects(service.loadAllWarData([tag],{throwOnError:true}),error=>error._tag==='ApiResponseError'&&error.status===status);
  assert.equal(service.getWarCwlByTag(tag),retained,'An outage replaced readable state');
 }
 await control(200,'',503,'inMaintenance');await assert.rejects(service.loadAllWarData([tag],{throwOnError:true}),error=>error._tag==='ApiResponseError'&&error.status===503);
 service.dispose();console.log('PASS real App war service: notInWar, private log, invalid credentials, maintenance, outages and retained readable state');
 `,
    },
    outfile: output,
    bundle: true,
    define: { __DEV__: 'false' },
    platform: 'node',
    format: 'esm',
    logLevel: 'silent',
  });
  const child = spawn(process.execPath, [output], { stdio: 'inherit', env: process.env });
  const [code] = await once(child, 'exit');
  assert.equal(code, 0);
} finally {
  rmSync(dir, { recursive: true, force: true });
}
