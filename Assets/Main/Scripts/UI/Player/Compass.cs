using UnityEngine;
using UnityEngine.UI;

public class Compass : MonoBehaviour
{
    private RawImage compassImage
    {
        get
        {
            if (_compassImage == null)
                TryGetComponent(out _compassImage);

            return _compassImage;
        }
    }
    private RawImage _compassImage;
    [SerializeField] private Transform compassTransform;

    void Update()
    {
        compassImage.uvRect = new Rect(compassTransform.localEulerAngles.y / 360f, 0, 1, 1);
    }
}