using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine.Experimental.Rendering.HDPipeline;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;

namespace UnityEngine.Experimental.Rendering
{
    using UnityObject = UnityEngine.Object;

    [Flags]
    public enum ClearFlag
    {
        None  = 0,
        Color = 1,
        Depth = 2,

        All = Depth | Color
    }

    public static class CoreUtils
    {
        public static List<RenderPipelineMaterial> GetRenderPipelineMaterialList()
        {
            var baseType = typeof(RenderPipelineMaterial);
            var assembly = baseType.Assembly;

            var types = assembly.GetTypes()
                .Where(t => t.IsSubclassOf(baseType))
                .Select(Activator.CreateInstance)
                .Cast<RenderPipelineMaterial>()
                .ToList();

            // Note: If there is a need for an optimization in the future of this function, user can
            // simply fill the materialList manually by commenting the code abode and returning a
            // custom list of materials they use in their game.
            //
            // return new List<RenderPipelineMaterial>
            // {
            //    new Lit(),
            //    new Unlit(),
            //    ...
            // };

            return types;
        }

        // Render Target Management.
        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier buffer, ClearFlag clearFlag, Color clearColor, int miplevel = 0, CubemapFace cubemapFace = CubemapFace.Unknown)
        {
            cmd.SetRenderTarget(buffer, miplevel, cubemapFace);

            if (clearFlag != ClearFlag.None)
                cmd.ClearRenderTarget((clearFlag & ClearFlag.Depth) != 0, (clearFlag & ClearFlag.Color) != 0, clearColor);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier buffer, ClearFlag clearFlag = ClearFlag.None, int miplevel = 0, CubemapFace cubemapFace = CubemapFace.Unknown)
        {
            SetRenderTarget(cmd, buffer, clearFlag, Color.black, miplevel, cubemapFace);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier colorBuffer, RenderTargetIdentifier depthBuffer, int miplevel = 0, CubemapFace cubemapFace = CubemapFace.Unknown)
        {
            SetRenderTarget(cmd, colorBuffer, depthBuffer, ClearFlag.None, Color.black, miplevel, cubemapFace);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier colorBuffer, RenderTargetIdentifier depthBuffer, ClearFlag clearFlag, int miplevel = 0, CubemapFace cubemapFace = CubemapFace.Unknown)
        {
            SetRenderTarget(cmd, colorBuffer, depthBuffer, clearFlag, Color.black, miplevel, cubemapFace);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier colorBuffer, RenderTargetIdentifier depthBuffer, ClearFlag clearFlag, Color clearColor, int miplevel = 0, CubemapFace cubemapFace = CubemapFace.Unknown)
        {
            cmd.SetRenderTarget(colorBuffer, depthBuffer, miplevel, cubemapFace);

            if (clearFlag != ClearFlag.None)
                cmd.ClearRenderTarget((clearFlag & ClearFlag.Depth) != 0, (clearFlag & ClearFlag.Color) != 0, clearColor);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier[] colorBuffers, RenderTargetIdentifier depthBuffer)
        {
            SetRenderTarget(cmd, colorBuffers, depthBuffer, ClearFlag.None, Color.black);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier[] colorBuffers, RenderTargetIdentifier depthBuffer, ClearFlag clearFlag = ClearFlag.None)
        {
            SetRenderTarget(cmd, colorBuffers, depthBuffer, clearFlag, Color.black);
        }

        public static void SetRenderTarget(CommandBuffer cmd, RenderTargetIdentifier[] colorBuffers, RenderTargetIdentifier depthBuffer, ClearFlag clearFlag, Color clearColor)
        {
            cmd.SetRenderTarget(colorBuffers, depthBuffer);

            if (clearFlag != ClearFlag.None)
                cmd.ClearRenderTarget((clearFlag & ClearFlag.Depth) != 0, (clearFlag & ClearFlag.Color) != 0, clearColor);
        }

        public static void ClearCubemap(CommandBuffer cmd, RenderTargetIdentifier buffer, Color clearColor)
        {
            for(int i = 0; i < 6; ++i)
                SetRenderTarget(cmd, buffer, ClearFlag.Color, Color.black, 0, (CubemapFace)i);
        }

        // Draws a full screen triangle as a faster alternative to drawing a full screen quad.
        public static void DrawFullScreen(CommandBuffer commandBuffer, Material material,
            MaterialPropertyBlock properties = null, int shaderPassId = 0)
        {
            commandBuffer.DrawProcedural(Matrix4x4.identity, material, shaderPassId, MeshTopology.Triangles, 3, 1, properties);
        }

        public static void DrawFullScreen(CommandBuffer commandBuffer, Material material,
            RenderTargetIdentifier colorBuffer,
            MaterialPropertyBlock properties = null, int shaderPassId = 0)
        {
            commandBuffer.SetRenderTarget(colorBuffer);
            commandBuffer.DrawProcedural(Matrix4x4.identity, material, shaderPassId, MeshTopology.Triangles, 3, 1, properties);
        }

        public static void DrawFullScreen(CommandBuffer commandBuffer, Material material,
            RenderTargetIdentifier colorBuffer, RenderTargetIdentifier depthStencilBuffer,
            MaterialPropertyBlock properties = null, int shaderPassId = 0)
        {
            commandBuffer.SetRenderTarget(colorBuffer, depthStencilBuffer);
            commandBuffer.DrawProcedural(Matrix4x4.identity, material, shaderPassId, MeshTopology.Triangles, 3, 1, properties);
        }

        public static void DrawFullScreen(CommandBuffer commandBuffer, Material material,
            RenderTargetIdentifier[] colorBuffers, RenderTargetIdentifier depthStencilBuffer,
            MaterialPropertyBlock properties = null, int shaderPassId = 0)
        {
            commandBuffer.SetRenderTarget(colorBuffers, depthStencilBuffer);
            commandBuffer.DrawProcedural(Matrix4x4.identity, material, shaderPassId, MeshTopology.Triangles, 3, 1, properties);
        }

        // Important: the first RenderTarget must be created with 0 depth bits!
        public static void DrawFullScreen(CommandBuffer commandBuffer, Material material,
            RenderTargetIdentifier[] colorBuffers,
            MaterialPropertyBlock properties = null, int shaderPassId = 0)
        {
            // It is currently not possible to have MRT without also setting a depth target.
            // To work around this deficiency of the CommandBuffer.SetRenderTarget() API,
            // we pass the first color target as the depth target. If it has 0 depth bits,
            // no depth target ends up being bound.
            DrawFullScreen(commandBuffer, material, colorBuffers, colorBuffers[0], properties, shaderPassId);
        }

        // Post-processing misc
        public static bool IsPostProcessingActive(PostProcessLayer layer)
        {
            return layer != null
                && layer.enabled;
        }

        public static bool IsTemporalAntialiasingActive(PostProcessLayer layer)
        {
            return IsPostProcessingActive(layer)
                && layer.antialiasingMode == PostProcessLayer.Antialiasing.TemporalAntialiasing
                && layer.temporalAntialiasing.IsSupported();
        }

        // Unity specifics
        public static Material CreateEngineMaterial(string shaderPath)
        {
            var mat = new Material(Shader.Find(shaderPath))
            {
                hideFlags = HideFlags.HideAndDontSave
            };
            return mat;
        }

        public static Material CreateEngineMaterial(Shader shader)
        {
            var mat = new Material(shader)
            {
                hideFlags = HideFlags.HideAndDontSave
            };
            return mat;
        }

        public static void SetKeyword(Material m, string keyword, bool state)
        {
            if (state)
                m.EnableKeyword(keyword);
            else
                m.DisableKeyword(keyword);
        }

        public static void SelectKeyword(Material material, string keyword1, string keyword2, bool enableFirst)
        {
            material.EnableKeyword(enableFirst ? keyword1 : keyword2);
            material.DisableKeyword(enableFirst ? keyword2 : keyword1);
        }

        public static void SelectKeyword(Material material, string[] keywords, int enabledKeywordIndex)
        {
            material.EnableKeyword(keywords[enabledKeywordIndex]);

            for (int i = 0; i < keywords.Length; i++)
            {
                if (i != enabledKeywordIndex)
                    material.DisableKeyword(keywords[i]);
            }
        }

        public static void Destroy(UnityObject obj)
        {
            if (obj != null)
            {
#if UNITY_EDITOR
                if (Application.isPlaying)
                    UnityObject.Destroy(obj);
                else
                    UnityObject.DestroyImmediate(obj);
#else
                UnityObject.Destroy(obj);
#endif
            }
        }

        public static void SafeRelease(ComputeBuffer buffer)
        {
            if (buffer != null)
                buffer.Release();
        }

        // Just a sort function that doesn't allocate memory
        // Note: Shoud be repalc by a radix sort for positive integer
        public static int Partition(uint[] numbers, int left, int right)
        {
            uint pivot = numbers[left];
            while (true)
            {
                while (numbers[left] < pivot)
                    left++;

                while (numbers[right] > pivot)
                    right--;

                if (left < right)
                {
                    uint temp = numbers[right];
                    numbers[right] = numbers[left];
                    numbers[left] = temp;
                }
                else
                {
                    return right;
                }
            }
        }

        public static void QuickSort(uint[] arr, int left, int right)
        {
            // For Recursion
            if (left < right)
            {
                int pivot = Partition(arr, left, right);

                if (pivot > 1)
                    QuickSort(arr, left, pivot - 1);

                if (pivot + 1 < right)
                    QuickSort(arr, pivot + 1, right);
            }
        }
    }
}
