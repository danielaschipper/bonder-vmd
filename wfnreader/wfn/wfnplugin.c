
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "molfile_plugin.h"

#include "periodic_table.h"

typedef struct {
  FILE *file;
  int numatoms;
  char *file_name;
  molfile_atom_t *atomlist;
  char coords;
} wfndata;
 
static void *open_wfn_read(const char *filename, const char *filetype, 
                           int *natoms) {
  FILE *fd;
  wfndata *data;
  int i;

  fd = fopen(filename, "rb");
  if (!fd) return NULL;
  char buffer[1000];
  data = (wfndata *)malloc(sizeof(wfndata));
  data->file = fd;
  data->file_name = strdup(filename);
  fgets(buffer,1000,data->file);
  /* First line is the number of atoms   */
  i = fscanf(data->file, "%*s %*s %*s %*s %*s %*s  %d", natoms);
  if (i < 1) {
    fprintf(stderr, "\n\nread) ERROR: wfn file '%s' should have the number of atoms in the second line.\n", filename);
    return NULL;
  }
  data->numatoms=*natoms;
  rewind(fd);

  return data;
}

static int read_wfn_structure(void *mydata, int *optflags, 
                              molfile_atom_t *atoms) {
  int i, j;
  char *k;
  float coord;
  molfile_atom_t *atom;
  wfndata *data = (wfndata *)mydata;
  char buffer[1024], fbuffer[1024];

  /* skip over the first two lines */
  if (NULL == fgets(fbuffer, 1024, data->file))  return MOLFILE_ERROR;
  if (NULL == fgets(fbuffer, 1024, data->file))  return MOLFILE_ERROR;

  /* we set atom mass and VDW radius from the PTE. */
  *optflags = MOLFILE_ATOMICNUMBER | MOLFILE_MASS | MOLFILE_RADIUS; 

  for(i=0; i<data->numatoms; i++) {
    k = fgets(fbuffer, 1024, data->file);
    atom = atoms + i;
    j=sscanf(fbuffer, "%s %*s %*s %*s %f %f %f", buffer, &coord, &coord, &coord);
    if (k == NULL) {
      fprintf(stderr, "wfn structure) missing atom(s) in file '%s'\n", data->file_name);
      fprintf(stderr, "wfn structure) expecting '%d' atoms, found only '%d'\n", data->numatoms, i);
      return MOLFILE_ERROR;
    } else if (j < 4) {
      fprintf(stderr, "wfn structure) missing type or coordinate(s) in file '%s' for atom '%d'\n",
          data->file_name, i+1);
      return MOLFILE_ERROR;
    }

    int idx;
    strncpy(atom->name, buffer, sizeof(atom->name));
    idx = get_pte_idx(buffer);
    atom->atomicnumber = idx;
    atom->mass = get_pte_mass(idx);
    atom->radius = get_pte_vdw_radius(idx);
    strncpy(atom->type, atom->name, sizeof(atom->type));
    atom->resname[0] = '\0';
    atom->resid = 1;
    atom->chain[0] = '\0';
    atom->segid[0] = '\0';
    /* skip to the end of line */
  }
  data->coords = 0;
  rewind(data->file);
  return MOLFILE_SUCCESS;
}



static int read_wfn_timestep(void *mydata, int natoms, molfile_timestep_t *ts) {
  int i, j;
  char atom_name[1024], fbuffer[1024], *k;
  float x, y, z;
  
  wfndata *data = (wfndata *)mydata;
  if (data->coords)
  	return MOLFILE_EOF;
  data->coords = 1;
  /* skip over the first two lines */
  if (NULL == fgets(fbuffer, 1024, data->file))  return MOLFILE_ERROR;
  if (NULL == fgets(fbuffer, 1024, data->file))  return MOLFILE_ERROR;

  /* read the coordinates */
  for (i=0; i<natoms; i++) {
    k = fgets(fbuffer, 1024, data->file);

    /* Read in atom type, X, Y, Z, skipping any remaining data fields */
    j = sscanf(fbuffer, " %s %*s %*s %*s %f %f %f", atom_name, &x, &y, &z);
    if (k == NULL) {
      return MOLFILE_ERROR;
    } else if (j < 4) {
      fprintf(stderr, "wfn timestep) missing type or coordinate(s) in file '%s' for atom '%d'\n",data->file_name,i+1);
      return MOLFILE_ERROR;
    } else if (j >= 4) {
      if (ts != NULL) {
        /* only save coords if we're given a timestep pointer, */
        /* otherwise assume that VMD wants us to skip past it. */
        ts->coords[3*i  ] = x * 0.52917721092;
        ts->coords[3*i+1] = y * 0.52917721092;
        ts->coords[3*i+2] = z * 0.52917721092;
      }
    } else {
      break;
    }
  }

  return MOLFILE_SUCCESS;
}


static void close_wfn_read(void *mydata) {
  wfndata *data = (wfndata *)mydata;
  fclose(data->file);
  free(data->file_name);
  free(data);
}



static molfile_plugin_t plugin;

VMDPLUGIN_API int VMDPLUGIN_init() {
  memset(&plugin, 0, sizeof(molfile_plugin_t));
  plugin.abiversion = vmdplugin_ABIVERSION;
  plugin.type = MOLFILE_PLUGIN_TYPE;
  plugin.name = "wfn";
  plugin.prettyname = "wfn";
  plugin.author = "Daniel Schipper";
  plugin.majorv = 1;
  plugin.minorv = 1;
  plugin.is_reentrant = VMDPLUGIN_THREADSAFE;
  plugin.filename_extension = "wfn";
  plugin.open_file_read = open_wfn_read;
  plugin.read_structure = read_wfn_structure;
  plugin.read_next_timestep = read_wfn_timestep;
  plugin.close_file_read = close_wfn_read;
  return VMDPLUGIN_SUCCESS;
}

VMDPLUGIN_API int VMDPLUGIN_register(void *v, vmdplugin_register_cb cb) {
  (*cb)(v, (vmdplugin_t *)&plugin);
  return VMDPLUGIN_SUCCESS;
}

VMDPLUGIN_API int VMDPLUGIN_fini() {
  return VMDPLUGIN_SUCCESS;
}


#ifdef TEST_PLUGIN

int main(int argc, char *argv[]) {
  molfile_timestep_t timestep;
  void *v;
  int natoms;
  int i, nsets, set;

  while (--argc) {
    ++argv;
    v = open_wfn_read(*argv, "wfn", &natoms);
    if (!v) {
      fprintf(stderr, "open_wfn_read failed for file %s\n", *argv);
      return 1;
    }
    fprintf(stderr, "open_wfn_read succeeded for file %s\n", *argv);
    fprintf(stderr, "number of atoms: %d\n", natoms);


    close_xyz_read(v);
  }
  return 0;
}

#endif

