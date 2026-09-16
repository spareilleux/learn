// draco3dgltf ships no type declarations: the two factories glTF Transform needs
declare module 'draco3dgltf' {
  const draco3d: {
    createEncoderModule(): Promise<unknown>;
    createDecoderModule(): Promise<unknown>;
  };
  export default draco3d;
}
