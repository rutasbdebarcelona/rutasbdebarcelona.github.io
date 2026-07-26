export type Locale = 'es' | 'en';

export const ui = {
  es: {
    menu: 'Menú', navigation: 'Navegación principal', home: 'inicio', routes: 'Rutas', compare: 'Comparar', guide: 'Quién guía', faq: 'Preguntas', contact: 'Contacto', book: 'Reservar ruta',
    footerCopy: 'Rutas culturales para entender Barcelona con contexto, cercanía y una mirada propia.', explore: 'Explorar', allRoutes: 'Todas las rutas', compareRoutes: 'Comparar rutas', bookRoute: 'Reservar una ruta', information: 'Información', privacy: 'Privacidad', terms: 'Condiciones', admin: 'Acceso privado', skip: 'Saltar al contenido'
  },
  en: {
    menu: 'Menu', navigation: 'Main navigation', home: 'home', routes: 'Tours', compare: 'Compare', guide: 'Your guide', faq: 'Questions', contact: 'Contact', book: 'Book a tour',
    footerCopy: 'Cultural tours to understand Barcelona through context, conversation and a distinctive point of view.', explore: 'Explore', allRoutes: 'All tours', compareRoutes: 'Compare tours', bookRoute: 'Book a tour', information: 'Information', privacy: 'Privacy', terms: 'Terms', admin: 'Private access', skip: 'Skip to content'
  }
} as const;
