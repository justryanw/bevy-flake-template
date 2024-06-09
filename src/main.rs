use bevy::{asset::AssetMetaCheck, prelude::*};

fn main() {
    App::new()
        .insert_resource(ClearColor(Color::BLACK))
        .insert_resource(AssetMetaCheck::Never)
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Bevy game".to_string(), // ToDo
                // Bind to canvas included in `index.html`
                canvas: Some("#bevy".to_owned()),
                // Tells wasm not to override default event handling, like F5 and Ctrl+R
                prevent_default_event_handling: false,
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, setup)
        .add_systems(Update, rotate)
        .run();
}

fn setup(
    mut commands: Commands,
    asset_server: Res<AssetServer>,
) {
    // Camera
    commands.spawn(Camera2dBundle::default());

    // Sprite
    commands.spawn(SpriteBundle {
        texture: asset_server.load("bevy.png"),
        ..default()
    });
}

fn rotate(mut query: Query<&mut Transform, With<Sprite>>, time: Res<Time>) {
    for mut bevy in &mut query {
        bevy.rotate_local_z(-time.delta_seconds());
    }
}
