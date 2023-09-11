using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameplayCamera : MonoBehaviour
{
    #region Camera variables

    public float cameraAdjustTime = 0.25f;
    public Camera myCamera
    {
        get
        {
            if (_myCamera == null)
                _myCamera = GetComponentInChildren<Camera>();

            return _myCamera;
        }
    }
    private Camera _myCamera;

    public GameThing cameraObject;

    public Vector3 cameraOffset = new Vector3(0f, 3.5f, -7f), cameraRotation = new Vector3(22.5f, 0f, 0f);

    #endregion

    #region Camera functions

    [SerializeField, Min(0.01f)] private float cameraSensitivity = 1f;
    [SerializeField] private Vector2 rotationLimits = new Vector2(-90f, 90f);
    Vector2 rotation = Vector2.zero;
    private Vector3 rotationAmount = Vector3.zero;
    public void Rotate(Vector3 rotation)
    {
        rotationAmount = rotation * cameraSensitivity;
    }

    /// <summary>
    /// Start is called on the frame when a script is enabled just before
    /// any of the Update methods is called the first time.
    /// </summary>
    void Start()
    {
        // Hide the cursor
        Cursor.visible = false;

        // Lock the cursor
        Cursor.lockState = CursorLockMode.Locked;
    }

    /// <summary>
    /// LateUpdate is called every frame, if the Behaviour is enabled.
    /// It is called after all Update functions have been called.
    /// </summary>
    void LateUpdate()
    {
        if (rotationAmount != Vector3.zero)
        {
            rotation.x += rotationAmount.x * Time.deltaTime;
            rotation.y += rotationAmount.y * Time.deltaTime;

            rotation.x = Mathf.Clamp(rotation.x, rotationLimits.x, rotationLimits.y);

            var xQuaternion = Quaternion.AngleAxis(rotation.x, Vector3.left);
            var yQuaternion = Quaternion.AngleAxis(rotation.y, Vector3.up);

            transform.localRotation = yQuaternion * xQuaternion;
        }
    }

    public void SetCameraObject(GameThing thingToFollow, float cameraHeight = 0.5f, bool immediateCameraShift = false)
    {
        if (centeringCamera && thingToFollow == cameraObject)
            return;

        if (thingToFollow == null)
        {
            Debug.LogError("Tried to set camera object to null!");
            return;
        }

        if (thingToFollow.GetAttachedThing() != null)
        {
            SetCameraObject(thingToFollow.GetAttachedThing(), cameraHeight, immediateCameraShift);
            return;
        }

        cameraObject = thingToFollow;

        transform.SetParent(thingToFollow.transform, true);

        if (immediateCameraShift)
        {
            transform.localPosition = Vector3.Lerp(Vector3.zero, cameraObject.thingTop.position, cameraHeight);
            transform.localEulerAngles = cameraRotation;

            myCamera.transform.localPosition = cameraOffset;
        }
        else
            CenterCamera(-1f, Vector3.Lerp(Vector3.zero, cameraObject.thingTop.position, cameraHeight));

        // Debug.Log("Set follow object to " + thingToFollow.name);
    }

    public void CenterCamera(float centerTime = -1f, Vector3? gotoPosition = null)
    {
        centeringCamera = true;
        if (centerTime < 0f)
            centerTime = cameraAdjustTime;

        StartCoroutine(CenterCameraCoroutine(centerTime, gotoPosition));
    }

    private IEnumerator CenterCameraCoroutine(float centerTime, Vector3? gotoPosition = null)
    {
        Vector3 startPosition = transform.localPosition;
        Vector3 cameraStartOffset = myCamera.transform.localPosition;
        Quaternion startRotation = transform.localRotation;

        float elapsedTime = 0f;
        Vector3 targetPosition = gotoPosition ?? Vector3.zero;
        while (elapsedTime < centerTime)
        {
            transform.localPosition = Vector3.Lerp(startPosition, targetPosition, elapsedTime / centerTime);
            transform.localRotation = Quaternion.Lerp(startRotation, Quaternion.Euler(cameraRotation), elapsedTime / centerTime);

            myCamera.transform.localPosition = Vector3.Lerp(cameraStartOffset, cameraOffset, elapsedTime / centerTime);

            elapsedTime += Time.deltaTime;
            yield return null;
        }

        transform.localPosition = targetPosition;
        transform.localRotation = Quaternion.Euler(cameraRotation);

        centeringCamera = false;
    }
    private bool centeringCamera;

    #endregion
}
