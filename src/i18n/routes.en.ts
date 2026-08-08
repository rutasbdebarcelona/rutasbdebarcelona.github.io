import type { TourRoute } from '../data/routes';

export const routeTranslationsEn:Record<string,Partial<TourRoute>>={
 'sagrada-familia':{
  title:'From Gaudí to the Sagrada Família · Day tour',eyebrow:'Architecture · city · living work',
  promise:'Discover the Sagrada Família in daylight on an outdoor guided tour. Read its façades, Gaudí’s vision and the work that still transforms Barcelona.',
  description:'See the Sagrada Família in clear daylight with an expert guide. Walk around the basilica to understand how the project began before Gaudí, how he transformed its scale and language, and why successive generations continue the work.',
  statusLabel:'Available',duration:'Approximately 75 minutes',format:'Guided walking tour · outdoors',area:'Sagrada Família',languages:['Spanish','English'],
  audience:['Independent travellers','Couples','Small groups','Hotels and agencies'],startingPoint:'Avinguda de Gaudí, 2, beside KFC.',endingPoint:'Area around the Glory Façade.',
  stops:['Plaça de Gaudí: origins and transformation','Nativity Façade','Apse: heritage and transformation','Passion Façade','Glory Façade: city and future'],
  includes:['In-person guide','Outdoor interpretive tour','Five visual stops'],notIncluded:['Admission to the basilica','Transport','Personal expenses'],
  accessibility:'Outdoor urban route. Any required adjustments are coordinated before the visit.',priceIndividual:'€20 per person',priceGroup:'',
  imageAlt:'Sagrada Família viewed from Plaça de Gaudí.'
 },
 'sagrada-familia-nocturna':{
  title:'From Gaudí to the Sagrada Família · Night tour',eyebrow:'Architecture · light · night-time cityscape',
  promise:'Discover the Sagrada Família at night, when light and shadow transform its façades and reveal another way to read Gaudí’s work.',
  description:'See how the Sagrada Família changes after dark. Walk around the basilica to understand the origin and evolution of the project while adding a distinct perceptual reading shaped by night lighting and shadow.',
  statusLabel:'Available',duration:'Approximately 75 minutes',format:'Guided walking tour · outdoors at night',area:'Sagrada Família',languages:['Spanish','English'],
  audience:['Independent travellers','Couples','Small groups','Hotels and agencies'],startingPoint:'Avinguda de Gaudí, 2, beside KFC.',endingPoint:'Area around the Glory Façade.',
  stops:['Plaça de Gaudí: the night-time silhouette','Nativity Façade','Apse: transition and light','Passion Façade','Glory Façade and closing view'],
  includes:['In-person guide','Outdoor night-time interpretive tour','Five visual stops'],notIncluded:['Admission to the basilica','Transport','Personal expenses'],
  accessibility:'Outdoor urban night route. Any required adjustments are coordinated before the visit.',priceIndividual:'€20 per person',priceGroup:'',
  imageAlt:'Nativity Façade illuminated at night.'
 },
 barcino:{title:'Medieval Barcino',eyebrow:'Roman Barcelona · medieval city · urban memory',promise:'Cross the Gothic Quarter by reading the layers Barcelona preserves and reconstructs.',description:'The Roman gate, aqueducts, walls and medieval city reveal how each period occupies, transforms and retells the same space.',statusLabel:'In preparation',duration:'To be confirmed',format:'Outdoor urban walk',area:'Gothic Quarter',languages:['Spanish','English'],audience:['Cultural visitors','Small groups','Educational programmes'],startingPoint:'Around COAC / Plaça Nova.',endingPoint:'To be confirmed.',stops:['Entrance to Barcino','Casa de l’Ardiaca','Cathedral and Sant Iu','Palau del Lloctinent','Temple of Augustus','Pont del Bisbe and Sant Jaume'],includes:['In-person guide','Urban and historical interpretation'],notIncluded:['Admission to monuments','Transport'],accessibility:'Full accessibility review pending.',priceIndividual:'',priceGroup:''},
 cafeborn:{title:'CafèBorn',statusLabel:'Hidden'}
};
export function toEnglishRoute(route:TourRoute):TourRoute{const stored=route.translationEn||{};return{...route,...(routeTranslationsEn[route.slug]||{}),...stored,statusLabel:stored.statusLabel||(route.status==='available'?'Available':'In preparation')}}
export function toEnglishRoutes(routes:TourRoute[]):TourRoute[]{return routes.map(toEnglishRoute)}
