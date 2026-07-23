import { useState } from 'react'
import { xpToNextLevel } from '../profile/progress'
import {
  AVATARS,
  avatarLabel,
  hasCharacter,
  loadProfile,
  saveProfile,
  type AvatarId,
  type Profile as ProfileState,
} from '../profile/store'
import type { Lang } from '../i18n/dict'
import { t } from '../i18n/dict'

interface ProfileProps {
  lang: Lang
  onBack: () => void
}

export function ProfileScreen({ lang, onBack }: ProfileProps) {
  const [profile, setProfile] = useState<ProfileState>(() => loadProfile())
  const [nameDraft, setNameDraft] = useState(profile.name)
  const [avatarDraft, setAvatarDraft] = useState<AvatarId>(profile.avatar)
  const [msg, setMsg] = useState('')

  const created = hasCharacter(profile)
  const need = xpToNextLevel(profile.level)
  const pct = Math.min(100, Math.round((profile.xp / need) * 100))

  function persist(next: ProfileState) {
    saveProfile(next)
    setProfile(next)
  }

  function onCreateOrSave() {
    const name = nameDraft.trim()
    if (name.length < 1) {
      setMsg(t(lang, 'profileNameRequired'))
      return
    }
    if (name.length > 20) {
      setMsg(t(lang, 'profileNameTooLong'))
      return
    }
    const next: ProfileState = {
      ...profile,
      name,
      avatar: avatarDraft,
      createdAt: profile.createdAt ?? new Date().toISOString(),
    }
    persist(next)
    setMsg(created ? t(lang, 'profileSaved') : t(lang, 'profileCreated'))
  }

  return (
    <section className="screen profile-screen">
      <header className="screen-head">
        <h2>{t(lang, 'profile')}</h2>
        <button type="button" className="btn" onClick={onBack}>
          {t(lang, 'back')}
        </button>
      </header>

      {!created && <p className="solo-lead">{t(lang, 'profileLead')}</p>}

      {created && (
        <div className="profile-card" role="region" aria-label={t(lang, 'profile')}>
          <p className="profile-name">
            <span className="profile-avatar-badge" aria-hidden="true">
              {avatarLabel(profile.avatar, lang).slice(0, 1)}
            </span>
            {profile.name}
          </p>
          <p className="meta mono">
            {t(lang, 'profileLevel')} {profile.level} · XP {profile.xp}/{need}
          </p>
          <div
            className="xp-bar"
            role="progressbar"
            aria-valuemin={0}
            aria-valuemax={need}
            aria-valuenow={profile.xp}
            aria-label={`${t(lang, 'profileXp')} ${profile.xp} / ${need}`}
          >
            <div className="xp-bar-fill" style={{ width: `${pct}%` }} />
          </div>
          <dl className="profile-stats">
            <div>
              <dt>{t(lang, 'profileRecord')}</dt>
              <dd className="mono">
                {profile.wins}W / {profile.losses}L / {profile.draws}D
                <span className="hint"> ({profile.gamesPlayed})</span>
              </dd>
            </div>
            <div>
              <dt>{t(lang, 'profileHighScore')}</dt>
              <dd className="mono">{profile.highScore}</dd>
            </div>
            <div>
              <dt>{t(lang, 'profileBestAi')}</dt>
              <dd className="mono">
                {profile.bestAiLevel > 0 ? profile.bestAiLevel : '—'}
              </dd>
            </div>
          </dl>
        </div>
      )}

      <label className="field">
        <span>{t(lang, 'profileName')}</span>
        <input
          value={nameDraft}
          maxLength={20}
          onChange={(e) => setNameDraft(e.target.value)}
          placeholder={t(lang, 'profileNamePlaceholder')}
          autoComplete="nickname"
        />
      </label>

      <fieldset className="field">
        <legend>{t(lang, 'profileAvatar')}</legend>
        <div className="avatar-row" role="group">
          {AVATARS.map((a) => (
            <button
              key={a.id}
              type="button"
              className={`btn avatar-btn${avatarDraft === a.id ? ' avatar-btn-on' : ''}`}
              aria-pressed={avatarDraft === a.id}
              onClick={() => setAvatarDraft(a.id)}
            >
              {lang === 'ko' ? a.labelKo : a.labelEn}
            </button>
          ))}
        </div>
      </fieldset>

      {msg && (
        <p className="done-msg" role="status">
          {msg}
        </p>
      )}

      <div className="btn-row">
        <button type="button" className="btn btn-primary" onClick={onCreateOrSave}>
          {created ? t(lang, 'profileSave') : t(lang, 'profileCreate')}
        </button>
      </div>
    </section>
  )
}
