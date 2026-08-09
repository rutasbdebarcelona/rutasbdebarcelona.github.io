export type RouteStatus='available'|'in-development'|'coming-soon';
export type RouteMediaKind='image'|'video'|'document'|'audio'|'map';
export type RouteMediaMode='hidden'|'single'|'carousel'|'grid';

export interface RouteMediaAsset {
 id:string;kind:RouteMediaKind;role:'hero'|'gallery'|'attachment';url:string;title:string;altText:string;mimeType:string;
}
export interface RouteStop {
 title:string;shortDescription?:string;fullDescription?:string;durationMinutes?:number;practicalInfo?:string;accessibility?:string;media?:string[];imageAlt?:string;
}
export interface RoutePageSettings {
 galleryMode:RouteMediaMode;stopsMediaMode:'hidden'|'single'|'carousel';stopsDisplayMode:'hidden'|'compact'|'cards';showHighlights:boolean;showMeetingPoint:boolean;showAccessibility:boolean;showLongDescription:boolean;
}
export interface TourRoute {
 slug:string;title:string;eyebrow:string;promise:string;description:string;status:RouteStatus;statusLabel:string;duration:string;format:string;area:string;
 languages:string[];audience:string[];startingPoint:string;endingPoint:string;stops:string[];stopDetails?:RouteStop[];highlights?:string[];includes:string[];notIncluded:string[];
 accessibility:string;priceIndividual:string;priceGroup:string;image:string;imageAlt:string;gallery?:RouteMediaAsset[];documents?:RouteMediaAsset[];
 meetingAddress?:string;meetingMapUrl?:string;meetingReference?:string;meetingInstructions?:string;meetingTransport?:string;scheduleNotes?:string;pageSettings?:RoutePageSettings;
 featured:boolean;published:boolean;translationEn?:Partial<TourRoute>;
}

const defaults:RoutePageSettings={galleryMode:'grid',stopsMediaMode:'carousel',stopsDisplayMode:'cards',showHighlights:true,showMeetingPoint:true,showAccessibility:true,showLongDescription:true};
const media=(slug:string,items:Array<[RouteMediaKind,string,string,string]>):RouteMediaAsset[]=>
 items.map(([kind,file,title,altText],index)=>({id:`${slug}-${index+1}`,kind,role:'gallery',url:file,title,altText,mimeType:kind==='video'?'video/mp4':'image/webp'}));

const dayStops:RouteStop[]=[
 {title:'Plaça de Gaudí: origen y transformación',shortDescription:'Una lectura general del conjunto para entender cómo nació el proyecto y qué cambió Gaudí.',durationMinutes:8,media:['/images/routes/sagrada-familia-diurna/plaza-gaudi.webp'],imageAlt:'Sagrada Família vista desde la Plaça de Gaudí con material gráfico de Rutas B.'},
 {title:'Fachada del Nacimiento',shortDescription:'Naturaleza, símbolos y continuidad del taller en la única fachada que Gaudí vio avanzar.',durationMinutes:10,media:['/images/routes/sagrada-familia-diurna/fachada-nacimiento.webp'],imageAlt:'Detalle diurno de la Fachada del Nacimiento.'},
 {title:'Ábside: herencia y transformación',shortDescription:'Una microparada para reconocer la transición entre el proyecto inicial y la arquitectura de Gaudí.',durationMinutes:4},
 {title:'Fachada de la Pasión',shortDescription:'Vacío, tensión y autoría: el contraste entre el lenguaje de Gaudí y la obra de Subirachs.',durationMinutes:10,media:['/images/routes/sagrada-familia-diurna/primer-plano-marca.webp'],imageAlt:'Material gráfico de Rutas B frente a la Sagrada Família.'},
 {title:'Fachada de la Gloria: ciudad y futuro',shortDescription:'La futura entrada principal permite cerrar la ruta conectando obra, técnica y transformación urbana.',durationMinutes:12,media:['/images/routes/sagrada-familia-diurna/contrapicado-marca.webp'],imageAlt:'Sagrada Família y marca Rutas B en contrapicado.'}
];
const nightStops:RouteStop[]=[
 {title:'Plaça de Gaudí: la silueta nocturna',shortDescription:'La iluminación concentra la mirada en la verticalidad, los volúmenes y las etapas constructivas.',durationMinutes:8,media:['/images/routes/sagrada-familia-nocturna/fachada-nacimiento.webp'],imageAlt:'Fachada del Nacimiento iluminada de noche.'},
 {title:'Fachada del Nacimiento',shortDescription:'Las sombras refuerzan la profundidad de las formas y ofrecen una lectura distinta de la observación diurna.',durationMinutes:10},
 {title:'Ábside: transición y luz',shortDescription:'Una pausa para reconocer la continuidad y los cambios del edificio en su perímetro.',durationMinutes:4,media:['/images/routes/sagrada-familia-nocturna/zona-abside.webp'],imageAlt:'Ábside y torres de la Sagrada Família iluminados de noche.'},
 {title:'Fachada de la Pasión',shortDescription:'El vacío, las columnas inclinadas y las sombras intensifican el dramatismo de esta fachada.',durationMinutes:10,media:['/videos/routes/sagrada-familia-nocturna/fachada-pasion.mp4'],imageAlt:'Video nocturno de la Fachada de la Pasión.'},
 {title:'Fachada de la Gloria y cierre',shortDescription:'El recorrido termina relacionando el futuro del templo con el paisaje nocturno de Barcelona.',durationMinutes:12}
];

export const routes:TourRoute[]=[
 {
  slug:'sagrada-familia',title:'De Gaudí a la Sagrada Família · Versión diurna',eyebrow:'Arquitectura · ciudad · obra viva',
  promise:'Descubre la Sagrada Família con luz diurna en una ruta exterior guiada. Lee sus fachadas, la visión de Gaudí y la obra que todavía transforma Barcelona.',
  description:'Contempla la Sagrada Família con la claridad de la luz diurna y un guía experto. Recorrerás el perímetro de la basílica para comprender cómo nació el proyecto antes de Gaudí, cómo el arquitecto transformó su magnitud y su lenguaje, y por qué la construcción continúa gracias al trabajo de sucesivas generaciones.',
  status:'available',statusLabel:'Disponible',duration:'Aproximadamente 75 minutos',format:'Visita guiada a pie · exterior',area:'Sagrada Família',
  languages:['Español','English'],audience:['Viajeros individuales','Parejas','Grupos pequeños','Hoteles y agencias'],
  startingPoint:'Avinguda de Gaudí, 2, junto al KFC.',endingPoint:'Entorno de la fachada de la Gloria.',
  stops:dayStops.map(stop=>stop.title),stopDetails:dayStops,
  highlights:['Observa relieves, geometrías, materiales y etapas constructivas con luz diurna.','Comprende el origen del proyecto antes de Gaudí y su transformación progresiva.','Compara los lenguajes de las fachadas del Nacimiento y de la Pasión.','Relaciona el futuro de la basílica con la historia urbana de Barcelona.'],
  includes:['Guía presencial','Ruta interpretativa exterior','Cinco paradas visuales'],notIncluded:['Entrada a la basílica','Transporte','Consumos personales'],
  accessibility:'Recorrido exterior urbano. Los ajustes necesarios se coordinan antes de la visita.',priceIndividual:'20 € por persona',priceGroup:'',
  image:'/images/routes/sagrada-familia-diurna/plaza-gaudi.webp',imageAlt:'Sagrada Família vista desde la Plaça de Gaudí.',
  gallery:media('sagrada-dia',[['image','/images/routes/sagrada-familia-diurna/contrapicado-marca.webp','Contrapicado y marca Rutas B','Vista en contrapicado de la Sagrada Família con material de Rutas B.'],['image','/images/routes/sagrada-familia-diurna/fachada-nacimiento.webp','Fachada del Nacimiento','Fachada del Nacimiento observada de día.'],['image','/images/routes/sagrada-familia-diurna/plaza-gaudi.webp','Plaça de Gaudí','Sagrada Família enmarcada por los árboles de la Plaça de Gaudí.'],['image','/images/routes/sagrada-familia-diurna/primer-plano-marca.webp','Una mirada propia','Marca Rutas B frente a la Sagrada Família.']]),
  meetingAddress:'Avinguda de Gaudí, 2',meetingReference:'KFC · Avinguda de Gaudí',meetingInstructions:'Busca al guía de Rutas B en el punto indicado.',meetingTransport:'Metro Sagrada Família (L2 y L5)',
  scheduleNotes:'Lunes a viernes: 18:00. Sábados y domingos: 10:00, 12:00 y 18:00.',pageSettings:defaults,featured:true,published:true
 },
 {
  slug:'sagrada-familia-nocturna',title:'De Gaudí a la Sagrada Família · Versión nocturna',eyebrow:'Arquitectura · luz · paisaje nocturno',
  promise:'Descubre la Sagrada Família de noche: la iluminación y las sombras transforman sus fachadas y revelan otra forma de leer la obra de Gaudí.',
  description:'Contempla la Sagrada Família cuando cae la noche y descubre cómo cambia su presencia en la ciudad. Recorrerás el perímetro para comprender el origen del proyecto, su transformación y la continuidad de la obra, incorporando una lectura perceptiva propia de la iluminación nocturna.',
  status:'available',statusLabel:'Disponible',duration:'Aproximadamente 75 minutos',format:'Visita guiada a pie · exterior nocturno',area:'Sagrada Família',
  languages:['Español','English'],audience:['Viajeros individuales','Parejas','Grupos pequeños','Hoteles y agencias'],
  startingPoint:'Avinguda de Gaudí, 2, junto al KFC.',endingPoint:'Entorno de la fachada de la Gloria.',
  stops:nightStops.map(stop=>stop.title),stopDetails:nightStops,
  highlights:['Descubre cómo la iluminación y las sombras transforman la lectura del templo.','Comprende el origen del proyecto y sus etapas constructivas.','Observa el contraste nocturno entre Nacimiento y Pasión.','Relaciona el futuro de la basílica con el paisaje nocturno de Barcelona.'],
  includes:['Guía presencial','Ruta interpretativa exterior nocturna','Cinco paradas visuales'],notIncluded:['Entrada a la basílica','Transporte','Consumos personales'],
  accessibility:'Recorrido exterior urbano nocturno. Los ajustes necesarios se coordinan antes de la visita.',priceIndividual:'20 € por persona',priceGroup:'',
  image:'/images/routes/sagrada-familia-nocturna/fachada-nacimiento.webp',imageAlt:'Fachada del Nacimiento iluminada de noche.',
  gallery:media('sagrada-noche',[['image','/images/routes/sagrada-familia-nocturna/fachada-nacimiento.webp','Fachada del Nacimiento de noche','Fachada del Nacimiento iluminada de noche.'],['image','/images/routes/sagrada-familia-nocturna/zona-abside.webp','Zona del ábside','Ábside y torres de la Sagrada Família de noche.'],['video','/videos/routes/sagrada-familia-nocturna/fachada-pasion.mp4','Fachada de la Pasión en movimiento','Video nocturno de la Fachada de la Pasión.']]),
  meetingAddress:'Avinguda de Gaudí, 2',meetingReference:'KFC · Avinguda de Gaudí',meetingInstructions:'Busca al guía de Rutas B en el punto indicado.',meetingTransport:'Metro Sagrada Família (L2 y L5)',
  scheduleNotes:'Todos los días: 22:00.',pageSettings:defaults,featured:true,published:true
 },
 {
  slug:'barcino',title:'Barcino medieval',eyebrow:'Roma · ciudad medieval · memoria urbana',promise:'Cruza el Gòtic leyendo las capas que Barcelona conserva y reconstruye.',
  description:'La puerta romana, los acueductos, las murallas y la ciudad medieval abren un recorrido donde cada época ocupa, transforma y vuelve a contar el mismo espacio.',
  status:'in-development',statusLabel:'En preparación',duration:'Pendiente de cierre',format:'Exterior · recorrido urbano',area:'Barri Gòtic',languages:['Español','English'],
  audience:['Visitantes culturales','Grupos pequeños','Programas educativos'],startingPoint:'Entorno del COAC / Plaça Nova.',endingPoint:'Pendiente de cierre.',
  stops:['Entrada a Barcino','Casa de l’Ardiaca','Catedral y Sant Iu','Palau del Lloctinent','Templo de Augusto','Pont del Bisbe y Sant Jaume'],
  includes:['Guía presencial','Lectura urbana e histórica'],notIncluded:['Entradas a recintos','Transporte'],accessibility:'Pendiente de auditoría completa.',
  priceIndividual:'',priceGroup:'',image:'/images/barcino.jpg',imageAlt:'Portal del Bisbe y muralla romana.',pageSettings:defaults,featured:true,published:true
 },
 {
  slug:'cafeborn',title:'CafèBorn',eyebrow:'Mercados · cultura · vida local',promise:'Una Barcelona que se reconoce en sus espacios culturales y calles cotidianas.',
  description:'Producto conservado como borrador editable.',status:'in-development',statusLabel:'Oculta',duration:'Pendiente',format:'Caminata cultural',area:'Sant Pere, Santa Caterina i la Ribera',
  languages:['Español','English'],audience:[],startingPoint:'',endingPoint:'',stops:[],includes:[],notIncluded:[],accessibility:'',priceIndividual:'',priceGroup:'',
  image:'/images/cafeborn.jpg',imageAlt:'Mercat de Santa Caterina.',pageSettings:defaults,featured:false,published:false
 }
];
export const publishedRoutes=routes.filter(route=>route.published);
export const getRoute=(slug:string)=>publishedRoutes.find(route=>route.slug===slug);
