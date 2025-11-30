
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class musictoggle : UdonSharpBehaviour
{
    [Header("Audio Sources (Order = Play Order)")]
    public AudioSource[] m_AudioSources; // Assign your 5 sources here in order

    [Tooltip("Start playing automatically on world load")] 
    public bool m_AutoPlayOnStart = false;

    private int _currentIndex = 0;
    private bool _isPaused = false;
    private bool _hasStartedPlayback = false;
    private bool _wasPlayingLastFrame = false;

    void Start()
    {
        // Make sure nothing is looping individually and nothing plays on awake
        StopAllAndReset();

        if (m_AutoPlayOnStart)
        {
            PlayCurrent();
        }
    }

    void Update()
    {
        AudioSource current = GetCurrent();
        if (current == null) return;

        // Detect transition from playing -> not playing (end of clip) while not paused
        bool isPlaying = current.isPlaying;
        if (_hasStartedPlayback && !_isPaused && _wasPlayingLastFrame && !isPlaying)
        {
            NextTrack();
        }
        _wasPlayingLastFrame = isPlaying;

        // Enforcement: if current is playing, make sure no other sources are also playing
        if (isPlaying)
        {
            StopAllExceptCurrent();
        }
    }

    public override void Interact()
    {
        base.Interact();
        TogglePlayPause();
    }

    // Public API: can be wired to buttons
    public void TogglePlayPause()
    {
        AudioSource current = GetCurrent();
        if (current == null) return;

        if (_isPaused)
        {
            current.Play();
            _isPaused = false;
            _hasStartedPlayback = true;
        }
        else
        {
            if (current.isPlaying)
            {
                current.Pause();
                _isPaused = true;
            }
            else
            {
                // Was stopped (end of track). Resume from start of current
                current.time = 0f;
                current.Play();
                _isPaused = false;
                _hasStartedPlayback = true;
            }
        }
    }

    public void NextTrack()
    {
        int next = GetNextIndex();
        SwitchToIndex(next);
    }

    public void PreviousTrack()
    {
        int prev = GetPrevIndex();
        SwitchToIndex(prev);
    }

    private void SwitchToIndex(int index)
    {
        if (!HasAnyTracks()) return;
        if (index < 0 || index >= m_AudioSources.Length) return;

        StopAllAndReset();
        _currentIndex = index;
        PlayCurrent();
    }

    private void PlayCurrent()
    {
        AudioSource current = GetCurrent();
        if (current == null) return;
        current.loop = false; // sequencing handles looping across tracks
        current.playOnAwake = false;
        current.time = 0f;
        StopAllExceptCurrent();
        current.Play();
        _isPaused = false;
        _hasStartedPlayback = true;
        _wasPlayingLastFrame = false;
    }

    private void StopAllExceptCurrent()
    {
        if (!HasAnyTracks()) return;
        for (int i = 0; i < m_AudioSources.Length; i++)
        {
            if (i == _currentIndex) continue;
            AudioSource src = m_AudioSources[i];
            if (src == null) continue;
            if (src.isPlaying) src.Stop();
        }
    }

    private void StopAllAndReset()
    {
        if (!HasAnyTracks()) return;

        for (int i = 0; i < m_AudioSources.Length; i++)
        {
            AudioSource src = m_AudioSources[i];
            if (src == null) continue;
            src.loop = false;
            src.playOnAwake = false;
            if (src.isPlaying) src.Stop();
            src.time = 0f;
        }
    }

    private int GetNextIndex()
    {
        if (!HasAnyTracks()) return 0;
        return ( _currentIndex + 1 ) % m_AudioSources.Length;
    }

    private int GetPrevIndex()
    {
        if (!HasAnyTracks()) return 0;
        int len = m_AudioSources.Length;
        return ( (_currentIndex - 1) + len ) % len;
    }

    private AudioSource GetCurrent()
    {
        if (!HasAnyTracks()) return null;
        AudioSource src = m_AudioSources[_currentIndex];
        // If the current is missing or has no clip, skip to next available
        if (src == null || src.clip == null)
        {
            // Try to find the next valid track
            for (int i = 0; i < m_AudioSources.Length; i++)
            {
                int idx = ( _currentIndex + i ) % m_AudioSources.Length;
                AudioSource candidate = m_AudioSources[idx];
                if (candidate != null && candidate.clip != null)
                {
                    _currentIndex = idx;
                    return candidate;
                }
            }
            return null;
        }
        return src;
    }

    private bool HasAnyTracks()
    {
        return m_AudioSources != null && m_AudioSources.Length > 0;
    }
}
