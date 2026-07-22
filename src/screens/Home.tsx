import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'

interface HomeProps {
  lang: Lang
  onNavigate: (screen: 'learn' | 'solo' | 'multi' | 'settings') => void
}

export function Home({ lang, onNavigate }: HomeProps) {
  return (
    <section className="home">
      <header className="hero">
        <h1 className="brand">{t(lang, 'appTitle')}</h1>
        <p className="tagline">{t(lang, 'tagline')}</p>
      </header>
      <nav className="main-nav" aria-label="main">
        <button type="button" className="btn btn-primary nav-btn" onClick={() => onNavigate('learn')}>
          {t(lang, 'learn')}
        </button>
        <button type="button" className="btn btn-primary nav-btn" onClick={() => onNavigate('solo')}>
          {t(lang, 'solo')}
        </button>
        <button type="button" className="btn btn-primary nav-btn" onClick={() => onNavigate('multi')}>
          {t(lang, 'multi')}
        </button>
        <button type="button" className="btn nav-btn" onClick={() => onNavigate('settings')}>
          {t(lang, 'settings')}
        </button>
      </nav>
    </section>
  )
}
