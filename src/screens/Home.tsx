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
  const need = created ? xpToNextLevel(profile.level) : 0

  return (
    <section className="home home--stitch">
      <div className="home-grid">
        <div className="home-brand-col">
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
                <span className="profile-home-top">
                  <span className="profile-avatar-badge" aria-hidden="true">
                    {avatarLabel(profile.avatar, lang).slice(0, 1)}
                  </span>
                  <span className="profile-home-meta">
                    <span className="nav-btn-title">
                      {avatarLabel(profile.avatar, lang)} · {profile.name}
                    </span>
                    <span className="nav-btn-sub mono">
                      {t(lang, 'profileLevel')} {profile.level} · {profile.wins}W/{profile.losses}L ·{' '}
                      {t(lang, 'profileHighScore')} {profile.highScore}
                    </span>
                  </span>
                </span>
                <span className="xp-bar home-xp" role="progressbar" aria-valuenow={profile.xp} aria-valuemin={0} aria-valuemax={need}>
                  <span className="xp-bar-fill" style={{ width: `${Math.min(100, Math.round((profile.xp / need) * 100))}%` }} />
                  <span className="xp-bar-label mono">
                    XP {profile.xp}/{need}
                  </span>
                </span>
              </>
            ) : (
              <>
                <span className="nav-btn-title">{t(lang, 'profileCreate')}</span>
                <span className="nav-btn-sub">{t(lang, 'profileLead')}</span>
              </>
            )}
          </button>
        </div>

        <nav className="main-nav" aria-label="main">
          <button
            type="button"
            className="btn btn-primary nav-btn nav-btn-core"
            onClick={() => onNavigate('solo')}
          >
            <span className="nav-btn-title">{t(lang, 'solo')}</span>
            <span className="nav-btn-sub">{t(lang, 'soloLead')}</span>
          </button>
          <button type="button" className="btn nav-btn" onClick={() => onNavigate('learn')}>
            {t(lang, 'learn')}
          </button>
          <button type="button" className="btn nav-btn" onClick={() => onNavigate('multi')}>
            {t(lang, 'multi')}
          </button>
          <button type="button" className="btn nav-btn nav-btn-muted" onClick={() => onNavigate('profile')}>
            {t(lang, 'profile')}
          </button>
          <button type="button" className="btn nav-btn nav-btn-muted" onClick={() => onNavigate('settings')}>
            {t(lang, 'settings')}
          </button>
        </nav>
      </div>
    </section>
  )
}
