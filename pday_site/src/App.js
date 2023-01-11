import "./App.css";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";
import { FontLoader } from "three/examples/jsm/loaders/FontLoader";
import { TextGeometry } from "three/examples/jsm/geometries/TextGeometry";
import React, { useEffect, useRef } from "react";
import logo from "./logo.svg";
const App = () => {
    const containerRef = useRef(null);

    useEffect(() => {
        // set up the scene
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(
            75,
            window.innerWidth / window.innerHeight,
            0.1,
            1000
        );
        camera.position.z = 5;
        const renderer = new THREE.WebGLRenderer({ antialias: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        containerRef.current.appendChild(renderer.domElement);
        const controls = new OrbitControls(camera, renderer.domElement);

        // create the cube
        const geometry = new THREE.BoxGeometry(2.5, 2.5, 2.5);
        const material = new THREE.MeshBasicMaterial({ color: 0xffffff }); // white background
        const texture = new THREE.TextureLoader().load(logo);
        texture.repeat.set(4 / 3, 4 / 3);
        texture.offset.set(-0.125, -0.125);
        material.map = texture;
        const cube = new THREE.Mesh(geometry, material);

        // white border with high thickness
        const border = new THREE.EdgesGeometry(geometry);
        const borderMaterial = new THREE.LineBasicMaterial({ color: 0xffffff });
        const borderMesh = new THREE.LineSegments(border, borderMaterial);
        const outerBorderMesh = borderMesh.clone();
        outerBorderMesh.scale.set(1.1, 1.1, 1.1);
        cube.add(borderMesh);
        cube.add(outerBorderMesh);
        scene.add(cube);

        // add some text
        /*
        const loader = new FontLoader();
        loader.load("/firacode.json", function (font) {
            const textGeometry = new TextGeometry("Welcome to 𝜋 Day 2023!", {
                font: font,
                size: 0.25,
                height: 0.1,
                curveSegments: 12,
                bevelEnabled: true,
                bevelThickness: 0.02,
                bevelSize: 0.01,
                bevelOffset: 0,
                bevelSegments: 5,
            });
								
            // Gruvbox graident texture
            const gruvbox = [
                {
                    stop: 0,
                    color: "#fb4934",
                },
                {
                    stop: 0.25,
                    color: "#b8bb26",
                },
                {
                    stop: 0.5,
                    color: "#fabd2f",
                },
                {
                    stop: 0.75,
                    color: "#83a598",
                },
                {
                    stop: 1,
                    color: "#d3869b",
                },
            ];

            function generateGradientTexture(colors) {
                const canvas = document.createElement("canvas");
                canvas.width = 256;
                canvas.height = 1;
                const ctx = canvas.getContext("2d");
                const gradient = ctx.createLinearGradient(0, 0, 256, 256);
                for (const color of colors) {
                    gradient.addColorStop(color.stop, color.color);
                }
                ctx.fillStyle = gradient;
                ctx.fillRect(0, 0, 256, 256);
                return canvas;
            }
				
            const textMaterial = new THREE.ShaderMaterial({
                uniforms: {
                    gradient: {
                        value: new THREE.CanvasTexture(
                            generateGradientTexture(gruvbox)
                        ),
                    },
                },
                vertexShader: `
								varying vec2 vUv;
								void main() {
									vUv = uv;
									gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
								}
							`,
                fragmentShader: `
								uniform sampler2D gradient;
								varying vec2 vUv;
								void main() {
									gl_FragColor = texture2D(gradient, vUv);
								}
							`,
            });
				    
				    const text = new THREE.Mesh(textGeometry, textMaterial);
				    text.geometry.computeBoundingBox();
				    text.position.set(text.geometry.boundingBox.max.x / -2, 0, 2.5);
            scene.add(text);
        });
				*/

        // start the animation loop
        const animate = () => {
            requestAnimationFrame(animate);
            cube.rotation.x += 0.01;
            cube.rotation.y += 0.01;
            renderer.render(scene, camera);
        };
        animate();
    }, []);

    return (
        <div id="main">
            <div ref={containerRef} />;
            <div id="filter" />
            <h1 id="t1">Welcome to 𝜋 Day</h1>
            <h1 id="ts">Welcome to 𝜋 Day</h1>
        </div>
    );
};

export default App;
