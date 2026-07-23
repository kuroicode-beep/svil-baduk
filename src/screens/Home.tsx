import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'
import { hasCharacter, loadProfile, avatarLabel } from '../profile/store'
import { xpToNextLevel } from '../profile/progress'
import { APP_VERSION } from '../version'

interface HomeProps {
  lang: Lang
  onNavigate: (screen: 'learn' | 'solo' | 'multi' | 'settings' | 'profile') => void
}

export function Home({ lang, onNavigate }: HomeProps) {
  const profile = loadProfile()
  const created = hasCharacter(profile)

  return (
    <section className="home">
      <header className="hero">
        <h1 className="brand">{t(lang, 'appTitle')}</h1>
        <p className="tagline">{t(lang, 'tagline')}</p>
        <p className="version-badge mono" aria-label={`version ${APP_VERSION}`}>
          v{APP_VERSION}
        </p>
      </header>

      <button
        type="button"
        className="btn profile-home-card"
        onClick={() => onNavigate('profile')}
      >
        {created ? (
          <>
            <span className="nav-btn-title">
              {avatarLabel(profile.avatar, lang)} · {profile.name}
            </span>
            <span className="nav-btn-sub mono">
              {t(lang, 'profileLevel')} {profile.level} · {profile.wins}W/{profile.losses}L ·{' '}
              {t(lang, 'profileHighScore')} {profile.highScore} · XP {profile.xp}/
              {xpToNextLevel(profile.level)}
            </span>
          </>
        ) : (
          <>
            <span className="nav-btn-title">{t(lang, 'profileCreate')}</span>
            <span className="nav-btn-sub">{t(lang, 'profileLead')}</span>
          </>
        )}
      </button>

      <nav className="main-nav" aria-label="main">
        <button
          type="button"
          className="btn btn-primary nav-btn nav-btn-core"
          onClick={() => onNavigate('solo')}
        >
          <span className="nav-btn-title">{t(lang, 'solo')}</span>
          <span className="nav-btn-sub">{t(lang, 'soloLead')}</span>
        </button>
        <button type="button" className="btn btn-primary nav-btn" onClick={() => onNavigate('learn')}>
          {t(lang, 'learn')}
        </button>
        <button type="button" className="btn btn-primary nav-btn" onClick={() => onNavigate('multi')}>
          {t(lang, 'multi')}
        </button>
        <button type="button" className="btn nav-btn" onClick={() => onNavigate('profile')}>
          {t(lang, 'profile')}
        </button>
        <button type="button" className="btn nav-btn" onClick={() => onNavigate('settings')}>
          {t(lang, 'settings')}
        </button>
      </nav>
    </section>
  )
}
