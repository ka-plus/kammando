import com.github.c64lib.retroassembler.domain.AssemblerType

plugins {
    id("com.github.c64lib.retro-assembler") version "1.7.6"
    id("com.github.hierynomus.license") version "0.16.1"
}

retroProject {
    dialect = AssemblerType.KickAssembler
    dialectVersion = "5.25"
    libDirs = arrayOf(".ra/deps/c64lib", "build/charpad", "build/spritepad", "build/goattracker")
    libFromGitHub("c64lib/common", "0.5.0")
    libFromGitHub("c64lib/chipset", "0.5.0")
    libFromGitHub("c64lib/copper64", "0.5.0")
}

license {
    header = file("LICENSE")
    excludes(listOf(".ra"))
    include("**/*.asm")
    mapping("asm", "SLASHSTAR_STYLE")
}

tasks.register<com.hierynomus.gradle.license.tasks.LicenseFormat>("licenseFormatAsm") {
    source = fileTree(".") {
        include("**/*.asm")
        exclude(".ra")
        exclude("build")
    }
}
tasks.register<com.hierynomus.gradle.license.tasks.LicenseCheck>("licenseAsm") {
    source = fileTree(".") {
        include("**/*.asm")
        exclude(".ra")
        exclude("build")
    }
}
tasks["licenseFormat"].dependsOn("licenseFormatAsm")


preprocess {
    charpad {
      getInput().set(file("Commando - L1.ctm"))
      getUseBuildDir().set(true)
      outputs {
        meta {
          dialect = AssemblerType.KickAssembler
          output = file("playfield-meta.asm")
        }
        charset {
          output = file("playfield-charset.bin")
        }
        map {
            interleaver {
                output = file("playfield-map.bin")
            }
            interleaver {
            }
        }
      }
    }
}
