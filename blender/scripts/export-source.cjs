// Extract the historical browser scene once; normal runtime remains unchanged.
const fs=require('node:fs/promises');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH||'playwright');
(async()=>{
 const out=path.resolve(process.argv[2]||'PrivateAssets/Courtyard/Blender');await fs.mkdir(out,{recursive:true});
 const browser=await chromium.launch({headless:true});
 try{
  const page=await browser.newPage({viewport:{width:1280,height:720},acceptDownloads:true});
  page.on('console',m=>{if(m.type()==='error')console.error(m.text());});
  await page.goto('http://127.0.0.1:4173/tools/blender-transfer.html');
  await page.waitForFunction(()=>window.transferReady||window.transferError,{},{timeout:120000});
  const error=await page.evaluate(()=>window.transferError);if(error)throw Error(error);
  const downloadEvent=page.waitForEvent('download');
  await page.evaluate(()=>{const a=document.createElement('a');a.href=window.transferURL;a.download='source.glb';a.click();});
  const download=await downloadEvent;await download.saveAs(path.join(out,'source.glb'));
  await fs.writeFile(path.join(out,'source.json'),JSON.stringify(await page.evaluate(()=>window.transferMetadata),null,2));
  console.log(JSON.stringify({output:out,bytes:(await fs.stat(path.join(out,'source.glb'))).size}));
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
