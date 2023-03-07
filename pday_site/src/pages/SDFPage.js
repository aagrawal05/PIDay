import React, { useEffect, useRef } from "react";
import { useFrame } from "@react-three/fiber";
import * as THREE from 'three';
import Raymarcher from '../components/Raymarcher';
import Composer from '../components/Composer';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const SDFPage = React.memo(() => {
  const containerRef = useRef(null);

  useEffect(() => {
    const rm = new Raymarcher();
    rm.loadFragmentShader("shaders/test.glsl", (scope) => {
      scope.setUniform( "color0", "v3", new THREE.Vector3(0.9, 0.9, 0.0) ); //yellow
      scope.setUniform( "light0", "v3", new THREE.Vector3(-0.5, 0.75, -0.5) );
      scope.setUniform( "color1", "v3", new THREE.Vector3(0.0, 0.2, 0.9) ); //blue
      scope.setUniform( "light1", "v3", new THREE.Vector3( 0.5, -0.75, 0.5) );
    })

    const composer = new Composer(rm);

    rm.camera.position.z = 8;
    containerRef.current.appendChild(rm.domElement);
    new OrbitControls(rm.camera, containerRef.current.firstChild);

    window.addEventListener( "resize", onResize, false );
    onResize();

    function onResize(e) {
      rm.setSize( window.innerWidth, window.innerHeight );
      if( composer !=null ) composer.setSize( window.innerWidth, window.innerHeight );
    }

    function animate() {
      requestAnimationFrame( animate );
      if( rm.loaded ) {
        var l1 = rm.getUniform( "light1" );
        if( l1 != null ) {
          rm.getUniform( "light1" ).value.x = 20 * ( Math.cos( Date.now() * 0.001 ) );
          rm.getUniform( "light1" ).value.z = 20 * ( Math.sin( Date.now() * 0.001 ) );
        }
      }
      rm.update();
      rm.render();
      if(rm.loaded && composer !=null ) composer.render();
    }
    animate();
  }, []);

  return (
    <div ref={containerRef} />
  );
});

export default SDFPage;

