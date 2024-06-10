use bevy::{asset::AssetMetaCheck, prelude::*};

fn main() {
    App::new()
        .insert_resource(ClearColor(Color::BLACK))
        .insert_resource(AssetMetaCheck::Never)
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: "Bevy Flake Template".to_string(),
                canvas: Some("#bevy".to_owned()),
                prevent_default_event_handling: false,
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, setup)
        .add_systems(Update, rotate)
        .run();
}

fn setup(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn(Camera2dBundle::default());

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
