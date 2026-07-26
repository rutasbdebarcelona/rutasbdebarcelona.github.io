import type { TourRoute } from '../data/routes';
const translations: Record<string, Partial<TourRoute>> = {
  "sagrada-familia": {
    "title": "From Gaudí to the Sagrada Família",
    "eyebrow": "Architecture · city · living work",
    "promise": "An outdoor tour to understand Barcelona's most famous work without reducing it to a postcard.",
    "description": "We walk around the basilica to discover how Gaudí, the Eixample, faith, craftsmanship and more than a century of history continue to converse within a work that is still alive.",
    "statusLabel": "Available",
    "duration": "Approx. 75 minutes",
    "format": "Outdoor · short walk · 4 stops",
    "area": "Sagrada Família",
    "languages": [
      "Spanish",
      "English"
    ],
    "audience": [
      "Independent travellers",
      "Couples",
      "Small groups",
      "Hotels and agencies",
      "Educational programmes"
    ],
    "startingPoint": "Plaça de Gaudí, at a point with an open view of the basilica. Exact location confirmed with the booking.",
    "endingPoint": "Plaça de la Sagrada Família or the area around the Glory Façade, depending on local conditions.",
    "stops": [
      "Gaudí, the Eixample and the city",
      "Nativity Façade",
      "Passion Façade",
      "Glory, the future and the Barcelona to come"
    ],
    "includes": [
      "In-person guide",
      "Outdoor interpretive tour",
      "Four visual stops",
      "Recommendations to continue your visit"
    ],
    "notIncluded": [
      "Admission to the basilica",
      "Transport",
      "Personal expenses"
    ],
    "accessibility": "Outdoor urban route. Detailed accessibility and any required adjustments are confirmed before the tour.",
    "priceIndividual": "To be confirmed",
    "priceGroup": "To be confirmed",
    "imageAlt": "View of the Sagrada Família from one of its surrounding squares"
  },
  "barcino": {
    "title": "Barcino: entering the city through its layers",
    "eyebrow": "Rome · medieval city · urban memory",
    "promise": "Cross the Gothic Quarter as a time machine, reading the layers Barcelona preserves and reconstructs.",
    "description": "The Roman gate, aqueducts, walls and medieval city open a route where every period occupies, transforms and retells the same space.",
    "statusLabel": "In preparation",
    "duration": "Duration to be confirmed",
    "format": "Outdoor · urban walk",
    "area": "Gothic Quarter",
    "languages": [
      "Spanish",
      "English"
    ],
    "audience": [
      "Cultural visitors",
      "Small groups",
      "Educational programmes"
    ],
    "startingPoint": "Around the Architects' Association of Catalonia / Plaça Nova.",
    "endingPoint": "To be confirmed when the complete route is finalised.",
    "stops": [
      "Entrance to Barcino",
      "Casa de l'Ardiaca",
      "Cathedral and Sant Iu",
      "Palau del Lloctinent and Saló del Tinell",
      "Temple of Augustus",
      "Pont del Bisbe and Sant Jaume"
    ],
    "includes": [
      "In-person guide",
      "Urban and historical interpretation"
    ],
    "notIncluded": [
      "Admission to monuments",
      "Transport",
      "Personal expenses"
    ],
    "accessibility": "Full accessibility review pending.",
    "priceIndividual": "To be confirmed",
    "priceGroup": "To be confirmed",
    "imageAlt": "Portal del Bisbe and remains of Barcelona's Roman wall"
  },
  "cafeborn": {
    "title": "CafèBorn",
    "eyebrow": "Markets · culture · passages · local life",
    "promise": "A Barcelona revealed through its breakfasts, cultural spaces and everyday working streets.",
    "description": "An adaptable experience connecting Santa Caterina Market, Teatre Antic, the Palau de la Música and the passages of the Born and Sant Pere.",
    "statusLabel": "In preparation",
    "duration": "Mid-morning · final duration pending",
    "format": "Cultural walk · adaptable for visitors and partners",
    "area": "Sant Pere, Santa Caterina and La Ribera",
    "languages": [
      "Spanish",
      "English"
    ],
    "audience": [
      "Independent travellers",
      "Couples",
      "Hotels",
      "Incoming agencies",
      "Private groups"
    ],
    "startingPoint": "Commercial confirmation pending.",
    "endingPoint": "Commercial confirmation pending.",
    "stops": [
      "Santa Caterina Market",
      "Teatre Antic",
      "Palau de la Música",
      "Passages and the memory of work"
    ],
    "includes": [
      "In-person guide",
      "Cultural narrative of the neighbourhood"
    ],
    "notIncluded": [
      "Food, drinks and suppliers until agreements are finalised",
      "Transport"
    ],
    "accessibility": "Full accessibility review of the route and its suppliers pending.",
    "priceIndividual": "To be confirmed",
    "priceGroup": "To be confirmed",
    "imageAlt": "Colourful roof of Santa Caterina Market"
  }
};
export function toEnglishRoute(route: TourRoute): TourRoute { return { ...route, ...(translations[route.slug] || {}), statusLabel: route.status === 'available' ? 'Available' : 'In preparation' }; }
export function toEnglishRoutes(routes: TourRoute[]): TourRoute[] { return routes.map(toEnglishRoute); }
