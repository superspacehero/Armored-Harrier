using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NaughtyAttributes;

[System.Serializable]
//? this class is not essential, just make inspector and implementation nicer. Lets you call sfx.Play() without having to worry about nulls
public class SFX
{
    [SerializeField]
    public SFXClip sfx;

    public void Play()
    {
        Play(Vector3.zero);
    }
    
    public void Play(Vector3 position)
    {
        if (sfx != null)
        {
            SFXManager.instance.PlaySFX(sfx,position);
        }
    }

    public void Play(Vector3 position, float addedPitch)
    {
        if (sfx != null)
        {
            SFXManager.instance.PlaySFX(sfx, position, addedPitch);
        }
    }

    public void Play(AudioSource a)
    {
        if (sfx != null)
        {
            SFXManager.instance.PlaySFX(sfx,a);
        }
    }
}
