export type MediaLayout='original'|'cover'|'contain'|'mosaic';
export type MediaResult={file:File;original:File;corrected:boolean};

type MediaAssistantOptions={onPreview?:(file:File)=>void;defaultRatio?:string};

const ratios:Record<string,number|null>={original:null,'16/9':16/9,'3/2':3/2,'4/3':4/3,'1/1':1};

export function setupMediaAssistant(input:HTMLInputElement,options:MediaAssistantOptions={}){
  const panel=document.createElement('section');
  panel.className='media-corrector';panel.hidden=true;
  panel.innerHTML=`<div class="media-corrector-head"><div><strong>Corrector de imagen</strong><span data-media-diagnostic></span></div><span data-media-state>Esperando archivo</span></div><div class="media-corrector-layout"><figure><img data-media-preview alt="Vista previa corregida"></figure><div class="media-corrector-controls"><label>Disposición<select data-media-layout><option value="original">Conservar original</option><option value="cover">Recortar para llenar</option><option value="contain">Imagen completa y centrada</option><option value="mosaic">Mosaico</option></select></label><label>Proporción<select data-media-ratio><option value="original">Original</option><option value="16/9">Panorámica 16:9</option><option value="3/2">Horizontal 3:2</option><option value="4/3">Horizontal 4:3</option><option value="1/1">Cuadrada</option></select></label><label>Ancho máximo<select data-media-width><option value="1280">1280 px</option><option value="1600">1600 px</option><option value="1920" selected>1920 px</option><option value="2560">2560 px</option></select></label><label>Fondo<select data-media-background><option value="#f6f1e8">Crema</option><option value="#ffffff">Blanco</option><option value="#123c32">Verde</option><option value="transparent">Transparente</option></select></label><label class="range-field">Foco horizontal <output data-media-x-output>50%</output><input data-media-x type="range" min="0" max="100" value="50"></label><label class="range-field">Foco vertical <output data-media-y-output>50%</output><input data-media-y type="range" min="0" max="100" value="50"></label><label class="range-field">Calidad <output data-media-quality-output>88%</output><input data-media-quality type="range" min="65" max="95" value="88"></label></div></div><p data-media-help>El original se conserva. La corrección solo afecta la copia que se publica.</p>`;
  input.closest('.field')?.insertAdjacentElement('afterend',panel);
  const q=(selector:string)=>panel.querySelector(selector) as HTMLElement;
  const preview=q('[data-media-preview]') as HTMLImageElement,diagnostic=q('[data-media-diagnostic]'),state=q('[data-media-state]');
  const layout=q('[data-media-layout]') as HTMLSelectElement,ratio=q('[data-media-ratio]') as HTMLSelectElement,width=q('[data-media-width]') as HTMLSelectElement,background=q('[data-media-background]') as HTMLSelectElement;
  const x=q('[data-media-x]') as HTMLInputElement,y=q('[data-media-y]') as HTMLInputElement,quality=q('[data-media-quality]') as HTMLInputElement;
  let original:File|null=null,result:MediaResult|null=null,objectUrl='',timer=0;
  ratio.value=options.defaultRatio||'original';
  const updateOutputs=()=>{q('[data-media-x-output]').textContent=x.value+'%';q('[data-media-y-output]').textContent=y.value+'%';q('[data-media-quality-output]').textContent=quality.value+'%';};
  const schedule=()=>{updateOutputs();window.clearTimeout(timer);timer=window.setTimeout(()=>void process(),120);};
  async function process(){
    if(!original||!original.type.startsWith('image/'))return;
    state.textContent='Corrigiendo…';
    try{
      const image=await loadImage(original),sourceRatio=image.naturalWidth/image.naturalHeight,targetRatio=ratios[ratio.value]||sourceRatio,maxWidth=Number(width.value),targetWidth=layout.value==='mosaic'?maxWidth:Math.min(maxWidth,image.naturalWidth),targetHeight=Math.max(1,Math.round(targetWidth/targetRatio));
      diagnostic.textContent=`${image.naturalWidth} × ${image.naturalHeight} px · ${formatBytes(original.size)} · ${sourceRatio<.85?'vertical':sourceRatio>1.25?'horizontal':'casi cuadrada'}`;
      if(layout.value==='original'&&targetWidth===image.naturalWidth){setResult(original,false);state.textContent='Original listo';return;}
      const canvas=document.createElement('canvas');canvas.width=targetWidth;canvas.height=targetHeight;const context=canvas.getContext('2d',{alpha:true});if(!context)throw new Error('canvas_unavailable');
      if(background.value!=='transparent'){context.fillStyle=background.value;context.fillRect(0,0,targetWidth,targetHeight);}
      if(layout.value==='mosaic')drawMosaic(context,image,targetWidth,targetHeight);
      else if(layout.value==='contain')drawContain(context,image,targetWidth,targetHeight);
      else drawCover(context,image,targetWidth,targetHeight,Number(x.value)/100,Number(y.value)/100);
      const mime=background.value==='transparent'?'image/png':'image/webp',blob=await new Promise<Blob|null>(resolve=>canvas.toBlob(resolve,mime,Number(quality.value)/100));if(!blob)throw new Error('encode_failed');
      const extension=mime==='image/png'?'png':'webp',name=original.name.replace(/\.[^.]+$/,`-web.${extension}`),file=new File([blob],name,{type:mime,lastModified:Date.now()});setResult(file,true);state.textContent=`Lista · ${formatBytes(file.size)}${image.naturalWidth<1280?' · resolución limitada':''}`;
    }catch{result={file:original,original,corrected:false};state.textContent='No se pudo corregir; se conservará el original';options.onPreview?.(original);}
  }
  function setResult(file:File,corrected:boolean){result={file,original:original!,corrected};if(objectUrl)URL.revokeObjectURL(objectUrl);objectUrl=URL.createObjectURL(file);preview.src=objectUrl;options.onPreview?.(file);}
  input.addEventListener('change',()=>{const file=input.files?.[0]||null;original=file;result=file?{file,original:file,corrected:false}:null;if(!file){panel.hidden=true;return;}panel.hidden=false;panel.classList.toggle('is-file',!file.type.startsWith('image/'));if(!file.type.startsWith('image/')){diagnostic.textContent=`${file.type||'Archivo'} · ${formatBytes(file.size)}`;state.textContent='No necesita corrección';preview.removeAttribute('src');return;}const probe=new Image(),url=URL.createObjectURL(file);probe.onload=()=>{const sourceRatio=probe.naturalWidth/probe.naturalHeight;layout.value=sourceRatio<.9?'contain':'cover';if(ratio.value==='original')ratio.value=options.defaultRatio||'3/2';URL.revokeObjectURL(url);void process();};probe.onerror=()=>{URL.revokeObjectURL(url);state.textContent='Formato no legible por el navegador';};probe.src=url;});
  [layout,ratio,width,background,x,y,quality].forEach(control=>control.addEventListener('input',schedule));
  return {getResult:async()=>{if(original&&original.type.startsWith('image/')&&!result?.corrected)await process();return result;},reset:()=>{original=null;result=null;panel.hidden=true;if(objectUrl)URL.revokeObjectURL(objectUrl);objectUrl='';}};
}

function loadImage(file:File){return new Promise<HTMLImageElement>((resolve,reject)=>{const image=new Image(),url=URL.createObjectURL(file);image.onload=()=>{URL.revokeObjectURL(url);resolve(image)};image.onerror=()=>{URL.revokeObjectURL(url);reject(new Error('invalid_image'))};image.src=url;});}
function drawContain(context:CanvasRenderingContext2D,image:HTMLImageElement,width:number,height:number){const scale=Math.min(width/image.naturalWidth,height/image.naturalHeight),w=image.naturalWidth*scale,h=image.naturalHeight*scale;context.drawImage(image,(width-w)/2,(height-h)/2,w,h);}
function drawCover(context:CanvasRenderingContext2D,image:HTMLImageElement,width:number,height:number,focusX:number,focusY:number){const scale=Math.max(width/image.naturalWidth,height/image.naturalHeight),sourceWidth=width/scale,sourceHeight=height/scale,left=(image.naturalWidth-sourceWidth)*focusX,top=(image.naturalHeight-sourceHeight)*focusY;context.drawImage(image,left,top,sourceWidth,sourceHeight,0,0,width,height);}
function drawMosaic(context:CanvasRenderingContext2D,image:HTMLImageElement,width:number,height:number){const tileWidth=Math.max(180,Math.min(width/2,image.naturalWidth)),scale=tileWidth/image.naturalWidth,tileHeight=image.naturalHeight*scale;for(let top=0;top<height;top+=tileHeight)for(let left=0;left<width;left+=tileWidth)context.drawImage(image,left,top,tileWidth,tileHeight);}
function formatBytes(value:number){return value<1048576?`${Math.round(value/1024)} KB`:`${(value/1048576).toFixed(1)} MB`;}
