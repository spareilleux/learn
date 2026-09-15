// compare/L03Cast.java
record CameraState(double px, double py, double pz) {}

public class L03Cast {
    public static void main(String[] args) {
        Object parsed = "not a camera";
        try {
            var camera = (CameraState) parsed;
            System.out.println(camera);
        } catch (ClassCastException e) {
            System.out.println("(CameraState) parsed: " + e.getClass().getSimpleName());
        }
        if (parsed instanceof CameraState camera) {
            System.out.println(camera.pz());
        } else {
            System.out.println("parsed instanceof CameraState: false");
        }
    }
}
