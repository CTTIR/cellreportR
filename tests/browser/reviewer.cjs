const {chromium}=require('playwright-core');
const fs=require('fs');const crypto=require('crypto');const path=require('path');const assert=require('assert');
(async()=>{
 const d=process.env.CELLREPORT_REVIEW_TEST_OUTPUT, runtime=process.env.TMPDIR;assert(d&&runtime);assert(fs.statSync(d).isDirectory());
 const browser=await chromium.launch({executablePath:process.env.CELLREPORT_REVIEW_BROWSER||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--disable-background-networking','--disable-component-update','--disable-sync','--no-first-run'],downloadsPath:path.join(d,'downloads'),env:{...process.env,HOME:runtime,XDG_CONFIG_HOME:runtime,XDG_CACHE_HOME:runtime,TMPDIR:runtime,TMP:runtime,TEMP:runtime}});
 const external=[],requests=[],checks=[];let pages=[];
 try {
 for(let i=0;i<2;i++){
 const context=await browser.newContext({viewport:{width:390,height:844},acceptDownloads:true});
 await context.route('**/*',async route=>{const u=new URL(route.request().url());if(u.hostname==='127.0.0.1'&&u.port==='18743'){requests.push(u.pathname);await route.continue();}else{external.push(u.href);await route.abort();}});
 const page=await context.newPage();pages.push(page);await page.goto('http://127.0.0.1:18743');await page.locator('.cr-claim').first().waitFor();}
 const page=pages[0];const fixtureRoot=fs.readFileSync(path.join(d,'browser-root.txt'),'utf8').trim();
 for(const width of [320,390,1280]){
 await page.setViewportSize({width,height:900});
 const dimensions=await page.evaluate(()=>({viewport:innerWidth,width:document.documentElement.scrollWidth,cards:[...document.querySelectorAll('.cr-claim')].map(e=>({width:e.getBoundingClientRect().width,value:e.querySelector('.cr-claim-value').textContent}))}));
 assert(dimensions.width<=width,JSON.stringify(dimensions));assert(dimensions.cards.every(c=>c.width>=width-70||width>500));
 checks.push({mobile_layout:width,...dimensions});await page.screenshot({path:path.join(d,`browser-${width}.png`),fullPage:true});}
 assert.equal(await page.locator('.cr-claim-value').nth(1).textContent(),'<unsafe>');assert.equal(await page.locator('unsafe').count(),0);
 await page.locator('.cr-claim summary').first().focus();await page.keyboard.press('Enter');assert(await page.locator('.cr-claim details').first().getAttribute('open')!==null);
 assert.equal(await pages[1].locator('.cr-claim details').first().getAttribute('open'),null);checks.push('keyboard disclosure and session UI isolation');await page.setViewportSize({width:320,height:900});await page.screenshot({path:path.join(d,'browser-320-expanded.png'),fullPage:true});assert(await page.locator('.cr-claim details').first().innerText().then(t=>t.includes('Source SHA-256')&&t.includes('id=a')));
 assert(!((await page.locator('#preview').innerText()).includes('Page X of Y')));const boundary=JSON.parse(fs.readFileSync(path.join(d,'markup-rejection.json')));assert(boundary.title&&boundary.limitations&&boundary.nested_tag);assert.equal(await page.locator('#preview em').count(),0);assert((await page.locator('#preview').innerText()).includes('<em>literal</em>'));checks.push('HTML class rejection and literal plain-title escaping');const links={};for(const id of ['report_spec','report_audit','report_html','report_pdf','figure_1']){
 links[id]=await page.locator('#'+id).getAttribute('href');assert.notEqual(links[id],await pages[1].locator('#'+id).getAttribute('href'));
 const [download]=await Promise.all([page.waitForEvent('download',{timeout:180000}),page.locator('#'+id).click()]);await download.saveAs(path.join(d,'downloads',download.suggestedFilename()));assert.equal(await download.failure(),null);checks.push({download:id,name:download.suggestedFilename()});}
 const spec=JSON.parse(fs.readFileSync(path.join(d,'downloads/report-spec.json')));assert.equal(spec.custom_fields.claim_2,'<unsafe>');const audit=JSON.parse(fs.readFileSync(path.join(d,'downloads/report-audit.json')));assert.equal(audit.schema,'cellreportR-report-audit');assert.equal(audit.report.report_id,'example');assert.deepEqual(fs.readFileSync(path.join(d,'downloads/figure_1.pdf')),fs.readFileSync(path.join(fixtureRoot,'figure.pdf')));assert.equal(fs.readFileSync(path.join(d,'downloads/report-pdf.pdf')).subarray(0,5).toString(),'%PDF-');assert(fs.readFileSync(path.join(d,'downloads/report-html.html'),'utf8').includes('Example report'));checks.push('download payload identities, real HTML/PDF and distinct session URLs');
 for(const q of ['/sibling-secret.txt','/results.csv','/../../sibling-secret.txt','/file'+path.join(d,'sibling-secret.txt')]){const r=await page.request.get('http://127.0.0.1:18743'+q);assert(!((await r.text()).includes('SIBLING_SECRET_MARKER')));checks.push({path_probe:q,status:r.status()});}
 await page.evaluate(()=>Shiny.setInputValue('lab_value',999));assert.equal(await pages[1].locator('.cr-claim-value').first().textContent(),'1.25');
 const root=fs.readFileSync(path.join(d,'browser-root.txt'),'utf8').trim();fs.writeFileSync(path.join(root,'results.csv'),'changed\n');
 await page.locator('#refresh').click();await page.getByText('Source validation failed. Preview unavailable.').waitFor();
 for(const id of ['report_spec','report_audit','report_html','report_pdf','figure_1']){const r=await page.request.get(new URL(links[id],'http://127.0.0.1:18743').href);const body=await r.text();assert(r.status()>=400);assert(body.includes('no download was released'));assert(!body.includes(root));checks.push({blocked_download:id,status:r.status()});}
 await pages[1].locator('#refresh').click();await pages[1].getByText('Source validation failed. Preview unavailable.').waitFor();
 fs.writeFileSync(path.join(d,'browser-receipt.json'),JSON.stringify({status:'PASS',checks,external_blocked:external,requests,limitations:['Signature fixture not valid full PDF','Chromium background flags and browser-context routing; no network namespace isolation']},null,2));
 }catch(e){fs.writeFileSync(path.join(d,'browser-failure.json'),JSON.stringify({error:e.stack,checks,external,requests},null,2));throw e;}finally{await browser.close();}
})();
